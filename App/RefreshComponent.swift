import HotwireNative
import UIKit

final class RefreshComponent: BridgeComponent {
    override class var name: String { "refresh" }

    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    override func onReceive(message: Message) {
        if message.event == "connect" {
            let action = UIAction() { _ in
                self.reply(to: message.event)
            }

            guard let viewController else { return }
            let navigationItems = viewController.navigationItems

            navigationItems.buttonItem = nil
            navigationItems.refreshItem = UIBarButtonItem(
                title: "Refresh",
                image: UIImage(systemName: "arrow.clockwise"),
                primaryAction: action
            )

            viewController.navigationItem.rightBarButtonItems = navigationItems.items
        } else if (message.event == "disconnect") {
            guard let viewController else { return }

            let navigationItems = viewController.navigationItems
            navigationItems.refreshItem = nil

            viewController.navigationItem.rightBarButtonItems = navigationItems.items
        }
    }
}
