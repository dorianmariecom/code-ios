import Foundation

struct AppConfig {
    static let environment: String = {
        #if CODE_ENV_LOCALHOST
                return "localhost"
        #elseif CODE_ENV_DEVELOPMENT
                return "development"
        #elseif CODE_ENV_STAGING
                return "staging"
        #elseif CODE_ENV_PRODUCTION
                return "production"
        #else
                return "production"
        #endif
    }()
    
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
