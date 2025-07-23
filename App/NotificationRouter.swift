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
        let actionIdentifier = response.actionIdentifier
        var userInfo = response.notification.request.content.userInfo
        guard let path = userInfo["path"] as? String else { return }
        let url = AppConfig.baseURL.appending(path: path)

        if actionIdentifier.hasPrefix("ACTION_") {
            var request = URLRequest(url: url)

            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(AppConfig.csrfToken, forHTTPHeaderField: "X-CSRF-Token")

            userInfo["action"] = actionIdentifier

            do { request.httpBody = try JSONSerialization.data(withJSONObject: ["code": userInfo]) } catch {}
            do { _ = try await URLSession.shared.data(for: request) } catch {}
        } else {
            navigationHandler.route(url)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
