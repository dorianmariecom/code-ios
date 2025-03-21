import Foundation

struct AppConfig {
    static let environment: String = ProcessInfo.processInfo.environment["CODE_ENV"] ?? "production"
    
     static let baseDomain: String = {
        switch environment {
        case "localhost": return "http://localhost:3000"
        case "development": return "https://dev.codedorian.com"
        case "staging": return "https://staging.codedorian.com"
        default: return "https://codedorian.com"
        }
    }()
    
    static let baseURL: URL = URL(string: baseDomain)!
    static let configurationsURL: URL = URL(string: "\(baseDomain)/configurations/ios_v1.json")!
    static let devicesURL: URL = URL(string: "\(baseDomain)/devices")!
    static var csrfToken: String?
}
