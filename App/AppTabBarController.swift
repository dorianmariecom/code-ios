import HotwireNative
import UIKit
import WebKit

final class AppTabBarController: UITabBarController, NavigationHandler {
    private let navigatorDelegate: NavigatorDelegate?
    private var tabDefinitions = [AppTabDefinition]()
    private var navigators = [AppTabDefinition: Navigator]()
    private var startedNavigatorIDs = Set<ObjectIdentifier>()

    init(navigatorDelegate: NavigatorDelegate? = nil) {
        self.navigatorDelegate = navigatorDelegate
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(navigatorDelegate:) instead.")
    }

    func load(_ tabs: [AppTabDefinition], selecting preferredIndex: Int? = nil) {
        let previousSelectedNavigator = activeNavigator
        let previousNavigators = navigators

        self.tabDefinitions = tabs
        navigators = [:]

        for tab in tabs {
            if let navigator = previousNavigators[tab] {
                navigators[tab] = navigator
            }
        }

        if let preferredIndex,
           tabs.indices.contains(preferredIndex),
           let previousSelectedNavigator,
           !navigators.values.contains(where: { $0 === previousSelectedNavigator }),
           navigators[tabs[preferredIndex]] == nil {
            navigators[tabs[preferredIndex]] = previousSelectedNavigator
        }

        viewControllers = tabs.map { tab in
            let navigator = navigators[tab] ?? makeNavigator(for: tab)
            navigators[tab] = navigator
            configure(navigator, for: tab)
            return navigator.rootViewController
        }

        let requestedIndex = preferredIndex ?? selectedIndex
        let clampedIndex = min(max(requestedIndex, 0), max(tabs.count - 1, 0))
        selectedIndex = clampedIndex
    }

    func route(_ url: URL) {
        ensureSelectedTabStarted()
        activeNavigator?.route(url)
    }

    func route(_ proposal: VisitProposal) {
        ensureSelectedTabStarted()
        activeNavigator?.route(proposal)
    }

    func routeSelectedTabToRoot() {
        guard let currentTabDefinition else { return }
        startIfNeeded(tab: currentTabDefinition)
        navigators[currentTabDefinition]?.route(currentTabDefinition.url)
    }

    func selectTab(at index: Int) {
        guard tabDefinitions.indices.contains(index) else { return }
        selectedIndex = index
        ensureSelectedTabStarted()
    }

    var currentWebView: WKWebView? {
        activeNavigator?.activeWebView
    }

    var currentVisitableURL: URL? {
        activeNavigator?.session.activeVisitable?.currentVisitableURL
            ?? activeNavigator?.session.topmostVisitable?.currentVisitableURL
            ?? currentWebView?.url
    }

    private var currentTabDefinition: AppTabDefinition? {
        guard tabDefinitions.indices.contains(selectedIndex) else { return nil }
        return tabDefinitions[selectedIndex]
    }

    private var activeNavigator: Navigator? {
        guard let currentTabDefinition else { return nil }
        return navigators[currentTabDefinition]
    }

    private func ensureSelectedTabStarted() {
        guard let currentTabDefinition else { return }
        startIfNeeded(tab: currentTabDefinition)
    }

    private func startIfNeeded(tab: AppTabDefinition) {
        guard let navigator = navigators[tab] else { return }
        let navigatorID = ObjectIdentifier(navigator)
        guard !startedNavigatorIDs.contains(navigatorID) else { return }
        startedNavigatorIDs.insert(navigatorID)
        navigator.start()
    }

    private func makeNavigator(for tab: AppTabDefinition) -> Navigator {
        let navigator = Navigator(
            configuration: .init(
                name: tab.title,
                startLocation: tab.url
            ),
            delegate: navigatorDelegate
        )

        configure(navigator, for: tab)

        return navigator
    }

    private func configure(_ navigator: Navigator, for tab: AppTabDefinition) {
        navigator.rootViewController.tabBarItem = UITabBarItem(
            title: tab.title,
            image: UIImage(systemName: tab.imageSystemName),
            selectedImage: nil
        )
    }
}
