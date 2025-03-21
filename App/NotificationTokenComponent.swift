import HotwireNative
import UIKit
import UserNotifications

class NotificationTokenComponent: BridgeComponent {
    override class var name: String { "notification-token" }

    override func onReceive(message: Message) {
        Task { await requestNotificationPermission() }
    }

    private func requestNotificationPermission() async {
        do {
            let center = UNUserNotificationCenter.current()
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            _ = try await center.requestAuthorization(options: options)

            UIApplication.shared.registerForRemoteNotifications()
        } catch {}
    }
}
