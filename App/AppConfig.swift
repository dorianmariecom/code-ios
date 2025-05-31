import Foundation

struct AppConfig {
    static let environment: String = {
        #if CODE_ENV_TEST
                return "test"
        #elseif CODE_ENV_LOCALHOST
                return "localhost"
        #elseif CODE_ENV_DEVELOPMENT
                return "development"
        #elseif CODE_ENV_STAGING
                return "staging"
        #else
                return "production"
        #endif
    }()
    
    static let baseDomain: String = {
        switch environment {
        case "test": return "http://localhost:3000"
        case "localhost": return "http://localhost:3000"
        case "development": return "https://dev.codedorian.com"
        case "staging": return "https://staging.codedorian.com"
        default: return "https://codedorian.com"
        }
    }()
    
    static let baseURL: URL = URL(string: baseDomain)!
    static let defaultURL: URL = baseURL
    static let configurationsURL: URL = URL(string: "\(baseDomain)/configurations/ios_v2.json")!
    static let devicesURL: URL = URL(string: "\(baseDomain)/devices")!
    static var csrfToken: String?
    static var sceneDelegate: SceneDelegate?
}
