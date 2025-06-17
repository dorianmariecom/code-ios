import HotwireNative
import UIKit

class ButtonComponent: BridgeComponent {
    override class var name: String { "button" }

    override func onReceive(message: Message) {
        if message.event == "connect" {
            guard let data: MessageData = message.data() else { return }

            let viewController = delegate?.destination as? UIViewController
            let action = UIAction() { _ in
                self.reply(to: message.event)
            }
            
            AppConfig.menuItem = nil
            AppConfig.shareItem = nil
            AppConfig.refreshItem = nil
            AppConfig.buttonItem = UIBarButtonItem(title: data.title, primaryAction: action)
            
            viewController?.navigationItem.rightBarButtonItems = AppConfig.items
        } else if message.event == "disconnect" {
            let viewController = delegate?.destination as? UIViewController
            
            AppConfig.buttonItem = nil
            
            viewController?.navigationItem.rightBarButtonItems = AppConfig.items
        }
    }
}

private extension ButtonComponent {
    struct MessageData: Decodable {
        let title: String
    }
}
