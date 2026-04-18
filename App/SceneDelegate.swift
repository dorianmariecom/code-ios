import HotwireNative
import UIKit
import WebKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, NavigatorDelegate, UITabBarControllerDelegate, DeepLinkHandling {
    var window: UIWindow?

    private var tabBarController: AppTabBarController?
    private var notificationRouter: NotificationRouter?
    private var pendingDeepLinkURL: URL?
    private var hasRestoredInitialState = false
    private let userDefaults = UserDefaults.standard
    private var pendingScrollRestore: PendingScrollRestore?
    private var pendingScrollRestoreRetryWorkItem: DispatchWorkItem?
    private weak var observedScrollRestoreWebView: WKWebView?
    private var observedScrollRestoreURL: NSKeyValueObservation?
    private var observedScrollRestoreLoading: NSKeyValueObservation?
    private var observedScrollRestoreContentSize: NSKeyValueObservation?

    private enum StorageKeys {
        static let lastSelectedTabIndex = "lastSelectedTabIndex"
        static let lastSelectedTabURL = "lastSelectedTabURL"
        static let lastSelectedTabScrollOffsetY = "lastSelectedTabScrollOffsetY"
        static let lastSelectedTabScrollPositionY = "lastSelectedTabScrollPositionY"
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
        var lastContentHeight: CGFloat
        var stableMatchCount: Int
    }

    private func scrollLog(_ message: String) {
        let formattedMessage = "[ScrollRestore] \(message)"
        NSLog("%@", formattedMessage)
        print(formattedMessage)
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

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleIncomingURL(url)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return }
        handleIncomingURL(url)
    }

    func viewDidLoad() {
        let tabBarController = AppTabBarController(
            navigatorDelegate: self
        )

        self.tabBarController = tabBarController
        notificationRouter = NotificationRouter(
            navigationHandler: tabBarController,
            deepLinkHandler: self
        )

        tabBarController.load(AppTab.definitions)
        tabBarController.selectTab(at: 0)
        tabBarController.delegate = self
        window?.rootViewController = tabBarController

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().standardAppearance = appearance

        UNUserNotificationCenter.current().delegate = notificationRouter
    }

    func queueDeepLink(_ url: URL) {
        pendingDeepLinkURL = url
        routePendingDeepLinkIfNeeded()
    }

    func persistLastVisitedState() {
        saveCurrentVisibleState()
    }

    func updateTabs(_ tabs: [AppTabDefinition], from sourceURL: URL?) {
        guard !tabs.isEmpty else { return }
        guard shouldAcceptTabUpdate(from: sourceURL) else { return }

        let wasPlaceholderConfiguration = AppTab.isPlaceholderConfiguration
        AppTab.definitions = tabs

        guard let tabBarController else { return }

        tabBarController.load(tabs)

        if routePendingDeepLinkIfNeeded() {
            return
        }

        if !hasRestoredInitialState, let state = loadLastVisitedState() {
            hasRestoredInitialState = true
            let selectedIndex = min(max(state.tabIndex, 0), max(tabs.count - 1, 0))
            scrollLog("restore-start tab=\(selectedIndex) url=\(state.url.absoluteString) savedScrollY=\(state.scrollOffsetY)")
            tabBarController.selectTab(at: selectedIndex)
            tabBarController.route(state.url)
            scheduleScrollRestore(tabIndex: selectedIndex, url: state.url, scrollOffsetY: state.scrollOffsetY)
            return
        }

        hasRestoredInitialState = true
        clearPendingScrollRestore()
        tabBarController.selectTab(at: 0)

        if wasPlaceholderConfiguration {
            tabBarController.routeSelectedTabToRoot()
        }
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let currentIndex = tabBarController.selectedIndex

        if tabBarController.selectedViewController === viewController {
            routeToTabURL(tabIndex: currentIndex)
            return false
        }

        return true
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        routeToTabURL(tabIndex: tabBarController.selectedIndex)
    }

    @discardableResult
    private func routePendingDeepLinkIfNeeded() -> Bool {
        guard let tabBarController, let pendingDeepLinkURL else { return false }
        self.pendingDeepLinkURL = nil
        tabBarController.route(pendingDeepLinkURL)
        return true
    }

    private func scheduleScrollRestore(tabIndex: Int, url: URL, scrollOffsetY: CGFloat) {
        guard scrollOffsetY > 0 else {
            scrollLog("restore-skip reason=zero-scroll tab=\(tabIndex) url=\(url.absoluteString)")
            return
        }

        pendingScrollRestore = PendingScrollRestore(
            tabIndex: tabIndex,
            url: url,
            scrollOffsetY: scrollOffsetY,
            attempt: 0,
            lastContentHeight: 0,
            stableMatchCount: 0
        )

        scrollLog("restore-scheduled tab=\(tabIndex) url=\(url.absoluteString) scrollY=\(scrollOffsetY)")
        startObservingPendingScrollRestoreWebViewIfNeeded()
        attemptPendingScrollRestore()
    }

    private func attemptPendingScrollRestore() {
        guard var pending = pendingScrollRestore, let tabBarController else { return }

        guard pending.attempt < 60 else {
            scrollLog("restore-abandon reason=max-attempts tab=\(pending.tabIndex) url=\(pending.url.absoluteString) targetScrollY=\(pending.scrollOffsetY)")
            clearPendingScrollRestore()
            return
        }

        guard tabBarController.selectedIndex == pending.tabIndex else {
            scrollLog("restore-abandon reason=tab-changed selectedTab=\(tabBarController.selectedIndex) expectedTab=\(pending.tabIndex)")
            clearPendingScrollRestore()
            return
        }

        pending.attempt += 1
        pendingScrollRestore = pending

        if let webView = currentWebView() {
            startObservingPendingScrollRestore(webView)
            let currentURL = webView.url?.absoluteString ?? "nil"
            let currentOffsetY = webView.scrollView.contentOffset.y + webView.scrollView.adjustedContentInset.top
            scrollLog("restore-attempt=\(pending.attempt) webURL=\(currentURL) targetURL=\(pending.url.absoluteString) contentHeight=\(webView.scrollView.contentSize.height) boundsHeight=\(webView.scrollView.bounds.height) currentScrollY=\(currentOffsetY)")
        } else {
            scrollLog("restore-attempt=\(pending.attempt) webView=nil targetURL=\(pending.url.absoluteString)")
        }

        if let webView = currentWebView(),
           isSamePage(webView.url, as: pending.url) {
            let scrollView = webView.scrollView
            let contentHeight = scrollView.contentSize.height
            let targetRawOffsetY = pending.scrollOffsetY - scrollView.adjustedContentInset.top
            let maxOffsetY = max(
                contentHeight - scrollView.bounds.height + scrollView.adjustedContentInset.bottom,
                -scrollView.adjustedContentInset.top
            )
            let targetOffsetY = min(max(targetRawOffsetY, -scrollView.adjustedContentInset.top), maxOffsetY)

            if maxOffsetY > -scrollView.adjustedContentInset.top {
                scrollView.setContentOffset(CGPoint(x: 0, y: targetOffsetY), animated: false)
                webView.evaluateJavaScript("window.scrollTo(0, \(pending.scrollOffsetY));", completionHandler: nil)

                let restoredOffsetY = max(
                    scrollView.contentOffset.y + scrollView.adjustedContentInset.top,
                    0
                )

                scrollLog("restore-apply attempt=\(pending.attempt) targetOffsetY=\(targetOffsetY) maxOffsetY=\(maxOffsetY) resultingScrollY=\(restoredOffsetY)")

                if abs(restoredOffsetY - pending.scrollOffsetY) <= 1 || targetOffsetY >= maxOffsetY {
                    let contentHeightIsStable = abs(contentHeight - pending.lastContentHeight) <= 1
                    if contentHeightIsStable && !webView.isLoading {
                        pending.stableMatchCount += 1
                    } else {
                        pending.stableMatchCount = 0
                    }

                    pending.lastContentHeight = contentHeight
                    pendingScrollRestore = pending

                    scrollLog("restore-match attempt=\(pending.attempt) stableMatchCount=\(pending.stableMatchCount) contentHeight=\(contentHeight) isLoading=\(webView.isLoading)")

                    if pending.stableMatchCount >= 2 {
                        scrollLog("restore-complete attempt=\(pending.attempt) finalScrollY=\(restoredOffsetY) contentHeight=\(contentHeight)")
                        clearPendingScrollRestore()
                        return
                    }
                } else {
                    pending.lastContentHeight = contentHeight
                    pending.stableMatchCount = 0
                    pendingScrollRestore = pending
                }
            } else {
                scrollLog("restore-wait reason=content-too-short attempt=\(pending.attempt) maxOffsetY=\(maxOffsetY)")
            }
        } else if let webView = currentWebView() {
            let currentURL = webView.url?.absoluteString ?? "nil"
            scrollLog("restore-wait reason=url-mismatch attempt=\(pending.attempt) webURL=\(currentURL) targetURL=\(pending.url.absoluteString)")
        }

        schedulePendingScrollRestoreRetry()
    }

    private func saveCurrentVisibleState() {
        guard let tabBarController else { return }

        let tabIndex = tabBarController.selectedIndex
        let fallback = defaultURL(for: tabIndex)

        guard let webView = tabBarController.currentWebView else {
            scrollLog("save-state webView=nil tab=\(tabIndex) fallbackURL=\(fallback.absoluteString)")
            saveLastVisitedState(url: fallback, tabIndex: tabIndex, scrollOffsetY: 0)
            return
        }

        let currentURL = tabBarController.currentVisitableURL ?? webView.url ?? fallback
        let scrollPositionY = max(webView.scrollView.contentOffset.y + webView.scrollView.adjustedContentInset.top, 0)
        scrollLog("save-state tab=\(tabIndex) url=\(currentURL.absoluteString) scrollY=\(scrollPositionY) contentHeight=\(webView.scrollView.contentSize.height) boundsHeight=\(webView.scrollView.bounds.height)")
        saveLastVisitedState(url: currentURL, tabIndex: tabIndex, scrollOffsetY: scrollPositionY)
    }

    private func currentWebView() -> WKWebView? {
        tabBarController?.currentWebView
    }

    private func saveLastVisitedState(url: URL, tabIndex: Int, scrollOffsetY: CGFloat) {
        userDefaults.set(tabIndex, forKey: StorageKeys.lastSelectedTabIndex)
        userDefaults.set(url.absoluteString, forKey: StorageKeys.lastSelectedTabURL)
        userDefaults.set(Double(scrollOffsetY), forKey: StorageKeys.lastSelectedTabScrollOffsetY)
        userDefaults.set(Double(scrollOffsetY), forKey: StorageKeys.lastSelectedTabScrollPositionY)
        scrollLog("save-persisted tab=\(tabIndex) url=\(url.absoluteString) scrollY=\(scrollOffsetY)")
    }

    private func loadLastVisitedState() -> LastVisitedState? {
        guard let urlString = userDefaults.string(forKey: StorageKeys.lastSelectedTabURL),
              let url = URL(string: urlString) else {
            scrollLog("load-state missing")
            return nil
        }

        let tabIndex = userDefaults.integer(forKey: StorageKeys.lastSelectedTabIndex)
        let legacyScrollOffsetY = userDefaults.double(forKey: StorageKeys.lastSelectedTabScrollOffsetY)
        let scrollPositionY = userDefaults.double(forKey: StorageKeys.lastSelectedTabScrollPositionY)
        let scrollOffsetY = scrollPositionY > 0 ? scrollPositionY : legacyScrollOffsetY
        scrollLog("load-state tab=\(tabIndex) url=\(url.absoluteString) scrollY=\(scrollOffsetY) legacyScrollY=\(legacyScrollOffsetY)")
        return LastVisitedState(url: url, tabIndex: tabIndex, scrollOffsetY: CGFloat(scrollOffsetY))
    }

    private func defaultURL(for tabIndex: Int) -> URL {
        if AppTab.all.indices.contains(tabIndex) {
            return AppTab.all[tabIndex].url
        }

        return AppConfig.defaultURL
    }

    private func routeToTabURL(tabIndex: Int) {
        guard let tabBarController else { return }
        tabBarController.route(defaultURL(for: tabIndex))
    }

    private func schedulePendingScrollRestoreRetry() {
        pendingScrollRestoreRetryWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.attemptPendingScrollRestore()
        }

        pendingScrollRestoreRetryWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
    }

    private func startObservingPendingScrollRestoreWebViewIfNeeded() {
        guard let webView = currentWebView() else { return }
        startObservingPendingScrollRestore(webView)
    }

    private func startObservingPendingScrollRestore(_ webView: WKWebView) {
        guard observedScrollRestoreWebView !== webView else { return }

        observedScrollRestoreURL = nil
        observedScrollRestoreLoading = nil
        observedScrollRestoreContentSize = nil
        observedScrollRestoreWebView = webView
        scrollLog("observe-webview url=\(webView.url?.absoluteString ?? "nil")")

        observedScrollRestoreURL = webView.observe(\.url, options: [.new]) { [weak self] _, _ in
            self?.scrollLog("observe-event kind=url")
            self?.attemptPendingScrollRestore()
        }

        observedScrollRestoreLoading = webView.observe(\.isLoading, options: [.new]) { [weak self] _, _ in
            self?.scrollLog("observe-event kind=isLoading value=\(webView.isLoading)")
            self?.attemptPendingScrollRestore()
        }

        observedScrollRestoreContentSize = webView.scrollView.observe(\.contentSize, options: [.new]) { [weak self] _, _ in
            self?.scrollLog("observe-event kind=contentSize height=\(webView.scrollView.contentSize.height)")
            self?.attemptPendingScrollRestore()
        }
    }

    private func clearPendingScrollRestore() {
        if let pendingScrollRestore {
            scrollLog("restore-clear tab=\(pendingScrollRestore.tabIndex) url=\(pendingScrollRestore.url.absoluteString)")
        }
        pendingScrollRestore = nil
        pendingScrollRestoreRetryWorkItem?.cancel()
        pendingScrollRestoreRetryWorkItem = nil
        observedScrollRestoreURL = nil
        observedScrollRestoreLoading = nil
        observedScrollRestoreContentSize = nil
        observedScrollRestoreWebView = nil
    }

    private func isSamePage(_ lhs: URL?, as rhs: URL) -> Bool {
        guard let lhs else { return false }
        if lhs.absoluteString == rhs.absoluteString {
            return true
        }
        return urlStorageKey(for: lhs) == urlStorageKey(for: rhs)
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

    private func handleIncomingURL(_ url: URL) {
        queueDeepLink(normalizedInAppURL(from: url))
    }

    private func shouldAcceptTabUpdate(from sourceURL: URL?) -> Bool {
        guard let sourceURL else { return currentWebView() == nil }
        guard let currentURL = currentWebView()?.url else { return true }
        return isSamePage(currentURL, as: sourceURL)
    }

    private func normalizedInAppURL(from url: URL) -> URL {
        guard let sourceComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        guard var targetComponents = URLComponents(url: AppConfig.baseURL, resolvingAgainstBaseURL: false) else {
            return url
        }

        targetComponents.path = sourceComponents.path.isEmpty ? "/" : sourceComponents.path
        targetComponents.queryItems = sourceComponents.queryItems
        targetComponents.fragment = sourceComponents.fragment
        return targetComponents.url ?? url
    }
}
