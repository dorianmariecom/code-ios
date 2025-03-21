import HotwireNative
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    private var tabBarController : TabBarController? = nil
    private var notificationRouter : NotificationRouter? = nil

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        viewDidLoad()
    }
    
    func viewDidLoad() {
        tabBarController = TabBarController(sceneDelegate: self)
        window?.rootViewController = tabBarController
        notificationRouter = NotificationRouter(
            router: tabBarController
        )
    
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white

        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().standardAppearance = appearance

        UNUserNotificationCenter.current().delegate = notificationRouter
    }
}
