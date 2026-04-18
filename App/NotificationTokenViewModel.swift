import Foundation

class NotificationTokenViewModel {
    private let userDefaults = UserDefaults.standard

    private enum StorageKeys {
        static let currentNotificationToken = "currentNotificationToken"
    }

    func registerCurrentTokenIfAvailable() async {
        guard let token = userDefaults.string(forKey: StorageKeys.currentNotificationToken),
              !token.isEmpty else { return }

        await register(token)
    }

    func register(_ token: String) async {
        userDefaults.set(token, forKey: StorageKeys.currentNotificationToken)

        var request = URLRequest(url: AppConfig.devicesURL)

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(
            "application/x-www-form-urlencoded; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )
        request.setValue(AppConfig.csrfToken, forHTTPHeaderField: "X-CSRF-Token")
        request.httpBody = "device[token]=\(token)&device[platform]=ios".data(using: .utf8)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200..<300).contains(httpResponse.statusCode) else { return }
        } catch {}
    }
}
