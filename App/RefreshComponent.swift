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

            AppConfig.buttonItem = nil
            AppConfig.refreshItem = UIBarButtonItem(
                title: "Refresh",
                image: UIImage(systemName: "arrow.clockwise"),
                primaryAction: action
            )

            viewController?.navigationItem.rightBarButtonItems = AppConfig.items
        } else if (message.event == "disconnect") {
            AppConfig.refreshItem = nil

            viewController?.navigationItem.rightBarButtonItems = AppConfig.items
        }
    }
}
