import HotwireNative
import UIKit

class TabBarController: UITabBarController {
    private var navigators = [Navigator]()

    override var title: String? {
        didSet{
            tabBarItem.title = "you want"
        }
    }

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

        delegate = self

        viewControllers = Tab.all.map { tab in
            let navigator = Navigator(delegate: self)
            navigators.append(navigator)

            let controller = navigator.rootViewController
            controller.tabBarItem.title = tab.title
            controller.tabBarItem.image = UIImage(systemName: tab.image)
            return controller
        }

        tabBarController(self, didSelect: viewControllers!.first!)
    }
}

extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(
        _ tabBarController: UITabBarController,
        didSelect viewController: UIViewController
    ) {
        guard let index = viewControllers?.firstIndex(of: viewController)
        else { return }
    
        let tab = Tab.all[index]
        let url = URL(string: "\(AppConfig.baseDomain)\(tab.path)")!

        if !tab.isStarted {
            navigators[index].route(url)
            tab.isStarted = true
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
