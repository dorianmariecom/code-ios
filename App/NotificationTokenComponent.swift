import HotwireNative
import UIKit
import UserNotifications

class NotificationTokenComponent: BridgeComponent {
    override class var name: String { "notification-token" }
    private static var hasRequestedPermissionThisLaunch = false
    private static var hasRegisteredForRemoteNotificationsThisLaunch = false

    override func onReceive(message: Message) {
        if message.event == "connect" {
            Task { await requestNotificationPermission() }
        }
    }

    private func requestNotificationPermission() async {
        guard !Self.hasRequestedPermissionThisLaunch else { return }
        Self.hasRequestedPermissionThisLaunch = true

        do {
            let center = UNUserNotificationCenter.current()
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            _ = try await center.requestAuthorization(options: options)

            await MainActor.run {
                guard !Self.hasRegisteredForRemoteNotificationsThisLaunch else { return }
                Self.hasRegisteredForRemoteNotificationsThisLaunch = true
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {}
    }
}
