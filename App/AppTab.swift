import HotwireNative
import UIKit

enum AppTab {
    static var definitions = [AppTabDefinition.placeholder]

    static var all: [HotwireNative.HotwireTab] {
        definitions.map(\.hotwireTab)
    }

    static var isPlaceholderConfiguration: Bool {
        definitions == [.placeholder]
    }
}

struct AppTabDefinition: Hashable {
    let title: String
    let imageSystemName: String
    let path: String

    var url: URL {
        AppConfig.baseURL.appending(path: path)
    }

    var hotwireTab: HotwireNative.HotwireTab {
        HotwireNative.HotwireTab(
            title: title,
            image: UIImage(systemName: imageSystemName)!,
            url: url
        )
    }

    static let placeholder = AppTabDefinition(
        title: "loading…",
        imageSystemName: "circle.fill",
        path: ""
    )
}
