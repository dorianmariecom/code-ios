import HotwireNative
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, NavigatorDelegate {
    var window: UIWindow?
    
    private var tabBarController: HotwireTabBarController?

    private var notificationRouter: NotificationRouter?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        AppConfig.sceneDelegate = self
        viewDidLoad()
    }
    
    func viewDidLoad() {
        tabBarController = HotwireTabBarController(
            navigatorDelegate: self
        )

        notificationRouter = NotificationRouter(
            navigationHandler: tabBarController!
        )

        tabBarController?.load(HotwireTab.all)
        window?.rootViewController = tabBarController!
    
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().standardAppearance = appearance

        UNUserNotificationCenter.current().delegate = notificationRouter
    }
}
