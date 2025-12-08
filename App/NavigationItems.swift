import ObjectiveC
import UIKit

final class NavigationItems {
    var menuItem: UIBarButtonItem?
    var shareItem: UIBarButtonItem?
    var buttonItem: UIBarButtonItem?
    var refreshItem: UIBarButtonItem?

    var items: [UIBarButtonItem] {
        [menuItem, shareItem, refreshItem, buttonItem].compactMap { $0 }
    }
}

extension UIViewController {
    private struct AssociatedKeys {
        static var navigationItems = "navigationItems"
    }

    var navigationItems: NavigationItems {
        if let items = objc_getAssociatedObject(self, &AssociatedKeys.navigationItems) as? NavigationItems {
            return items
        }

        let items = NavigationItems()
        objc_setAssociatedObject(self, &AssociatedKeys.navigationItems, items, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return items
    }
}
