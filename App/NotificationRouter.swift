import HotwireNative
import UserNotifications

class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    private unowned let navigationHandler: NavigationHandler

    init(navigationHandler: NavigationHandler) {
        self.navigationHandler = navigationHandler
    }

    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        if let path = userInfo["path"] as? String {
            let url = AppConfig.baseURL.appending(path: path)
            navigationHandler.route(url)
        }
    }
}
