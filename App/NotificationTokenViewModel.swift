import Foundation

class NotificationTokenViewModel {
    func register(_ token: String) async {
        var request = URLRequest(url: AppConfig.devicesURL)

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(AppConfig.csrfToken, forHTTPHeaderField: "X-CSRF-Token")
        request.httpBody = "device[token]=\(token)&device[platform]=ios".data(using: .utf8)
    
        do { _ = try await URLSession.shared.data(for: request) } catch {}
    }
}
