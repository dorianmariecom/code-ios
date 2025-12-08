import HotwireNative
import UIKit

final class ShareComponent: BridgeComponent {
    override class var name: String { "share" }

    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    override func onReceive(message: Message) {
        if message.event == "connect" {
            guard
                let data: MessageData = message.data(),
                let url = URL(string: data.url),
                let viewController
            else { return }

            let action = UIAction { [weak self] _ in
                let activityViewController = UIActivityViewController(
                    activityItems: [url],
                    applicationActivities: nil
                )
                self?.viewController?.present(activityViewController, animated: false)
            }
            
            let navigationItems = viewController.navigationItems
            navigationItems.buttonItem = nil
            navigationItems.shareItem = UIBarButtonItem(
                title: "Share",
                image: UIImage(systemName: "square.and.arrow.up"),
                primaryAction: action
            )

            viewController.navigationItem.rightBarButtonItems = navigationItems.items
        } else if (message.event == "disconnect") {
            guard let viewController else { return }

            let navigationItems = viewController.navigationItems
            navigationItems.shareItem = nil

            viewController.navigationItem.rightBarButtonItems = navigationItems.items
        }
    }

    struct MessageData: Decodable {
        let url: String
    }
}
