import HotwireNative
import UIKit

extension HotwireTab {
    static var all = [
        HotwireTab(
            title: "loading...",
            image: UIImage(systemName: "circle.fill")!,
            url: AppConfig.defaultURL
        )
    ]
}

extension HotwireTab: Equatable {
    public static func == (lhs: HotwireTab, rhs: HotwireTab) -> Bool {
        return lhs.title == rhs.title && lhs.url == rhs.url
    }
}
