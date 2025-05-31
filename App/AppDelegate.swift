import HotwireNative
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let viewModel = NotificationTokenViewModel()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "unknown"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        
        Hotwire.config.debugLoggingEnabled = true
        Hotwire.config.applicationUserAgentPrefix = "\(bundleIdentifier)/\(appVersion)"
        
        Hotwire.loadPathConfiguration(from: [
            .server(AppConfig.configurationsURL)
        ])
        Hotwire.registerBridgeComponents([
            ButtonComponent.self,
            NotificationTokenComponent.self,
            TabBarComponent.self,
            CsrfTokenComponent.self,
            ConfirmComponent.self,
            MenuComponent.self,
            ShareComponent.self,
        ])
        return true
    }
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { await viewModel.register(token) }
    }    
}
