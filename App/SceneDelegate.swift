import HotwireNative
import UIKit
import WebKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, NavigatorDelegate, UITabBarControllerDelegate, DeepLinkHandling {
    var window: UIWindow?

    private var tabBarController: HotwireTabBarController?

    private var notificationRouter: NotificationRouter?

    private var pendingDeepLinkURL: URL?
    private var hasRestoredState = false
    private var tabsReady = false
    private let userDefaults = UserDefaults.standard
    private var pendingScrollRestore: PendingScrollRestore?

    private enum StorageKeys {
        static let lastSelectedTabIndex = "lastSelectedTabIndex"
        static let lastSelectedTabURL = "lastSelectedTabURL"
        static let lastSelectedTabScrollOffsetY = "lastSelectedTabScrollOffsetY" // legacy raw contentOffset.y
        static let lastSelectedTabScrollPositionY = "lastSelectedTabScrollPositionY" // contentOffset.y + adjustedContentInset.top
        static let scrollOffsetsByURL = "scrollOffsetsByURL"
        static let scrollPositionsByURL = "scrollPositionsByURL"
        static let tabURLsByIndex = "tabURLsByIndex"
    }

    private struct LastVisitedState {
        let url: URL
        let tabIndex: Int
        let scrollOffsetY: CGFloat
    }

    private struct PendingScrollRestore {
        let tabIndex: Int
        let url: URL
        let scrollOffsetY: CGFloat
        var attempt: Int
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        AppConfig.sceneDelegate = self
        viewDidLoad()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        saveCurrentVisibleState()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        saveCurrentVisibleState()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        saveCurrentVisibleState()
    }

    func viewDidLoad() {
        tabBarController = HotwireTabBarController(
            navigatorDelegate: self
        )

        notificationRouter = NotificationRouter(
            navigationHandler: tabBarController!,
            deepLinkHandler: self
        )

        tabBarController?.load(HotwireTab.all)
        tabBarController?.delegate = self
        window?.rootViewController = tabBarController!

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().standardAppearance = appearance

        UNUserNotificationCenter.current().delegate = notificationRouter

        markTabsReadyIfConfigured()
        attemptRestoreOrDeepLink()
    }

    func queueDeepLink(_ url: URL) {
        pendingDeepLinkURL = url
        attemptRestoreOrDeepLink()
    }

    func persistLastVisitedState() {
        saveCurrentVisibleState()
    }

    func tabsDidUpdate() {
        tabsReady = true
        guard let tabBarController else { return }
        tabBarController.load(HotwireTab.all)
        attemptRestoreOrDeepLink()
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        saveCurrentVisibleState(tabIndexOverride: tabBarController.selectedIndex)
        return true
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let tabIndex = tabBarController.selectedIndex
        restoreStateForTabSelection(tabIndex: tabIndex)
    }

    private func attemptRestoreOrDeepLink() {
        guard tabsReady, let tabBarController else { return }

        if let pendingDeepLinkURL {
            self.pendingDeepLinkURL = nil
            tabBarController.route(pendingDeepLinkURL)
            saveLastVisitedState(url: pendingDeepLinkURL, tabIndex: tabBarController.selectedIndex, scrollOffsetY: 0)
            hasRestoredState = true
            return
        }

        guard !hasRestoredState, let state = loadLastVisitedState() else { return }
        let maxIndex = max(0, (tabBarController.viewControllers?.count ?? 1) - 1)
        let selectedIndex = min(max(state.tabIndex, 0), maxIndex)
        tabBarController.selectedIndex = selectedIndex
        tabBarController.route(state.url)
        hasRestoredState = true
        scheduleScrollRestore(tabIndex: selectedIndex, url: state.url, scrollOffsetY: state.scrollOffsetY)
    }

    private func scheduleScrollRestore(tabIndex: Int, url: URL, scrollOffsetY: CGFloat) {
        guard scrollOffsetY > 0 else { return }

        pendingScrollRestore = PendingScrollRestore(
            tabIndex: tabIndex,
            url: url,
            scrollOffsetY: scrollOffsetY,
            attempt: 0
        )

        attemptPendingScrollRestore()
    }

    private func attemptPendingScrollRestore() {
        guard var pending = pendingScrollRestore, let tabBarController else { return }

        guard pending.attempt < 20 else {
            pendingScrollRestore = nil
            return
        }

        guard tabBarController.selectedIndex == pending.tabIndex else {
            pendingScrollRestore = nil
            return
        }

        pending.attempt += 1
        pendingScrollRestore = pending

        if let webView = currentWebView(),
           isSamePage(webView.url, as: pending.url) {
            let scrollView = webView.scrollView
            let targetRawOffsetY = pending.scrollOffsetY - scrollView.adjustedContentInset.top
            let maxOffsetY = max(
                scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom,
                -scrollView.adjustedContentInset.top
            )
            let targetOffsetY = min(max(targetRawOffsetY, -scrollView.adjustedContentInset.top), maxOffsetY)

            if maxOffsetY > -scrollView.adjustedContentInset.top {
                scrollView.setContentOffset(CGPoint(x: 0, y: targetOffsetY), animated: false)
                pendingScrollRestore = nil
                return
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.attemptPendingScrollRestore()
        }
    }

    private func saveCurrentVisibleState(fallbackURL: URL? = nil, tabIndexOverride: Int? = nil) {
        guard let tabBarController else { return }

        let tabIndex = tabIndexOverride ?? tabBarController.selectedIndex
        let fallback = fallbackURL ?? storedOrDefaultURL(for: tabIndex)

        guard let webView = currentWebView() else {
            saveLastVisitedState(url: fallback, tabIndex: tabIndex, scrollOffsetY: 0)
            return
        }

        let currentURL = webView.url ?? fallback
        let scrollPositionY = max(webView.scrollView.contentOffset.y + webView.scrollView.adjustedContentInset.top, 0)
        saveLastVisitedState(url: currentURL, tabIndex: tabIndex, scrollOffsetY: scrollPositionY)
    }

    private func currentWebView() -> WKWebView? {
        guard let selectedViewController = tabBarController?.selectedViewController else { return nil }

        if let navigationController = selectedViewController as? UINavigationController {
            return findWebView(in: navigationController.visibleViewController?.view)
                ?? findWebView(in: navigationController.topViewController?.view)
                ?? findWebView(in: navigationController.view)
        }

        return findWebView(in: selectedViewController.view)
    }

    private func findWebView(in view: UIView?) -> WKWebView? {
        guard let view else { return nil }

        if let webView = view as? WKWebView {
            return webView
        }

        for subview in view.subviews {
            if let webView = findWebView(in: subview) {
                return webView
            }
        }

        return nil
    }

    private func saveLastVisitedState(url: URL, tabIndex: Int, scrollOffsetY: CGFloat) {
        userDefaults.set(tabIndex, forKey: StorageKeys.lastSelectedTabIndex)
        userDefaults.set(url.absoluteString, forKey: StorageKeys.lastSelectedTabURL)
        userDefaults.set(Double(scrollOffsetY), forKey: StorageKeys.lastSelectedTabScrollOffsetY)
        userDefaults.set(Double(scrollOffsetY), forKey: StorageKeys.lastSelectedTabScrollPositionY)
        saveScrollOffset(scrollOffsetY, for: url)
        saveTabURL(url, for: tabIndex)
    }

    private func loadLastVisitedState() -> LastVisitedState? {
        guard let urlString = userDefaults.string(forKey: StorageKeys.lastSelectedTabURL),
              let url = URL(string: urlString) else {
            return nil
        }

        let tabIndex = userDefaults.integer(forKey: StorageKeys.lastSelectedTabIndex)
        let legacyScrollOffsetY = userDefaults.double(forKey: StorageKeys.lastSelectedTabScrollOffsetY)
        let scrollPositionY = userDefaults.double(forKey: StorageKeys.lastSelectedTabScrollPositionY)
        let scrollOffsetY = loadScrollOffset(for: url) ?? (scrollPositionY > 0 ? scrollPositionY : legacyScrollOffsetY)
        return LastVisitedState(url: url, tabIndex: tabIndex, scrollOffsetY: CGFloat(scrollOffsetY))
    }

    private func saveScrollOffset(_ scrollOffsetY: CGFloat, for url: URL) {
        let value = Double(max(scrollOffsetY, 0))

        var scrollPositionsByURL = userDefaults.dictionary(forKey: StorageKeys.scrollPositionsByURL) as? [String: Double] ?? [:]
        scrollPositionsByURL[url.absoluteString] = value
        scrollPositionsByURL[urlStorageKey(for: url)] = value
        userDefaults.set(scrollPositionsByURL, forKey: StorageKeys.scrollPositionsByURL)

        // Keep legacy map populated for backward compatibility.
        var scrollOffsetsByURL = userDefaults.dictionary(forKey: StorageKeys.scrollOffsetsByURL) as? [String: Double] ?? [:]
        scrollOffsetsByURL[url.absoluteString] = value
        scrollOffsetsByURL[urlStorageKey(for: url)] = value
        userDefaults.set(scrollOffsetsByURL, forKey: StorageKeys.scrollOffsetsByURL)
    }

    private func loadScrollOffset(for url: URL) -> Double? {
        let scrollPositionsByURL = userDefaults.dictionary(forKey: StorageKeys.scrollPositionsByURL) as? [String: Double]
        if let value = scrollPositionsByURL?[url.absoluteString] ?? scrollPositionsByURL?[urlStorageKey(for: url)] {
            return value
        }

        let scrollOffsetsByURL = userDefaults.dictionary(forKey: StorageKeys.scrollOffsetsByURL) as? [String: Double]
        return scrollOffsetsByURL?[url.absoluteString] ?? scrollOffsetsByURL?[urlStorageKey(for: url)]
    }

    private func storedOrDefaultURL(for tabIndex: Int) -> URL {
        if let url = loadTabURL(for: tabIndex) {
            return url
        }

        if let state = loadLastVisitedState(), state.tabIndex == tabIndex {
            return state.url
        }

        if HotwireTab.all.indices.contains(tabIndex) {
            return HotwireTab.all[tabIndex].url
        }

        return AppConfig.defaultURL
    }

    private func restoreStateForTabSelection(tabIndex: Int) {
        guard let tabBarController else { return }

        let targetURL = storedOrDefaultURL(for: tabIndex)
        let currentURL = currentWebView()?.url
        if !isSamePage(currentURL, as: targetURL) {
            tabBarController.route(targetURL)
        }

        let scrollOffsetY = loadScrollOffset(for: targetURL) ?? 0
        scheduleScrollRestore(tabIndex: tabIndex, url: targetURL, scrollOffsetY: CGFloat(scrollOffsetY))
    }

    private func markTabsReadyIfConfigured() {
        guard !tabsReady else { return }
        if HotwireTab.all.count != 1 {
            tabsReady = true
            return
        }
        if HotwireTab.all.first?.title != "loading…" {
            tabsReady = true
        }
    }

    private func isSamePage(_ lhs: URL?, as rhs: URL) -> Bool {
        guard let lhs else { return false }
        if lhs.absoluteString == rhs.absoluteString {
            return true
        }
        return urlStorageKey(for: lhs) == urlStorageKey(for: rhs)
    }

    private func saveTabURL(_ url: URL, for tabIndex: Int) {
        var tabURLsByIndex = userDefaults.dictionary(forKey: StorageKeys.tabURLsByIndex) as? [String: String] ?? [:]
        tabURLsByIndex[String(tabIndex)] = url.absoluteString
        userDefaults.set(tabURLsByIndex, forKey: StorageKeys.tabURLsByIndex)
    }

    private func loadTabURL(for tabIndex: Int) -> URL? {
        let tabURLsByIndex = userDefaults.dictionary(forKey: StorageKeys.tabURLsByIndex) as? [String: String]
        guard let urlString = tabURLsByIndex?[String(tabIndex)] else { return nil }
        return URL(string: urlString)
    }

    private func urlStorageKey(for url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }

        components.fragment = nil
        components.query = nil

        if components.path.count > 1 {
            components.path = components.path.replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
            if components.path.isEmpty {
                components.path = "/"
            }
        }

        components.scheme = components.scheme?.lowercased()
        components.host = components.host?.lowercased()
        return components.string ?? url.absoluteString
    }
}
