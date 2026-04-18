import HotwireNative
import UIKit
import UserNotifications

class NotificationTokenComponent: BridgeComponent {
    override class var name: String { "notification-token" }
    private let viewModel = NotificationTokenViewModel()
    private static var hasRequestedPermissionThisLaunch = false
    private static var hasRegisteredForRemoteNotificationsThisLaunch = false

    override func onReceive(message: Message) {
        if message.event == "connect" {
            Task { await syncNotificationToken() }
        }
    }

    private func syncNotificationToken() async {
        await viewModel.registerCurrentTokenIfAvailable()
        await requestNotificationPermissionIfNeeded()
    }

    private func requestNotificationPermissionIfNeeded() async {
        guard !Self.hasRequestedPermissionThisLaunch else { return }

        do {
            let center = UNUserNotificationCenter.current()
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            _ = try await center.requestAuthorization(options: options)

            Self.hasRequestedPermissionThisLaunch = true

            await MainActor.run {
                guard !Self.hasRegisteredForRemoteNotificationsThisLaunch else { return }
                Self.hasRegisteredForRemoteNotificationsThisLaunch = true
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {}
    }
}
