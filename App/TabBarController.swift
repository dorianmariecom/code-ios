import HotwireNative
import UIKit

class TabBarController: UITabBarController {
    private var navigators = [Navigator]()

    var sceneDelegate: SceneDelegate?
    
    init(sceneDelegate: SceneDelegate) {
        self.sceneDelegate = sceneDelegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init(coder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground() // Ensures solid color
        appearance.backgroundColor = .white

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance

        viewControllers = Tab.all.map { tab in
            let navigator = Navigator(delegate: self)
            navigator.route(AppConfig.baseURL.appending(path: tab.path))
            navigators.append(navigator)

            let controller = navigator.rootViewController
            controller.tabBarItem.title = tab.title
            controller.tabBarItem.image = UIImage(systemName: tab.image)
            return controller
        }
    }
}

extension TabBarController: NavigatorDelegate {}

extension TabBarController: Router {
    func route(_ url: URL) {
        navigators[selectedIndex].route(url)
    }

    func route(_ proposal: VisitProposal) {
        navigators[selectedIndex].route(proposal)
    }
}
