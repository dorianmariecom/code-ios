import Foundation

class NotificationTokenViewModel {
    private let userDefaults = UserDefaults.standard

    private enum StorageKeys {
        static let lastRegisteredNotificationToken = "lastRegisteredNotificationToken"
    }

    func register(_ token: String) async {
        guard userDefaults.string(forKey: StorageKeys.lastRegisteredNotificationToken) != token else { return }

        var request = URLRequest(url: AppConfig.devicesURL)

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(AppConfig.csrfToken, forHTTPHeaderField: "X-CSRF-Token")
        request.httpBody = "device[token]=\(token)&device[platform]=ios".data(using: .utf8)

        do {
            _ = try await URLSession.shared.data(for: request)
            userDefaults.set(token, forKey: StorageKeys.lastRegisteredNotificationToken)
        } catch {}
    }
}
