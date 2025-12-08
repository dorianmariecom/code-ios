import HotwireNative
import UIKit

class ButtonComponent: BridgeComponent {
    override class var name: String { "button" }

    override func onReceive(message: Message) {
        if message.event == "connect" {
            guard
                let data: MessageData = message.data(),
                let viewController = delegate?.destination as? UIViewController
            else { return }

            let action = UIAction() { _ in
                self.reply(to: message.event)
            }
            
            let navigationItems = viewController.navigationItems
            navigationItems.menuItem = nil
            navigationItems.shareItem = nil
            navigationItems.refreshItem = nil
            navigationItems.buttonItem = UIBarButtonItem(title: data.title, primaryAction: action)
            
            viewController.navigationItem.rightBarButtonItems = navigationItems.items
        } else if message.event == "disconnect" {
            guard let viewController = delegate?.destination as? UIViewController else { return }

            let navigationItems = viewController.navigationItems
            navigationItems.buttonItem = nil
            
            viewController.navigationItem.rightBarButtonItems = navigationItems.items
        }
    }
}

private extension ButtonComponent {
    struct MessageData: Decodable {
        let title: String
    }
}
