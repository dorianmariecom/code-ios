import HotwireNative
import UIKit

class ButtonComponent: BridgeComponent {
    override class var name: String { "button" }

    override func onReceive(message: Message) {
        if message.event == "connect" {
            connect(via: message)
        } else if message.event == "disconnect" {
            disconnect()
        }
    }

    private func connect(via message: Message) {
        guard let data: MessageData = message.data() else { return }

        let viewController = delegate.destination as? UIViewController
        let action = UIAction(title: data.title) { _ in
            self.reply(to: message.event)
        }
        let button = UIBarButtonItem(primaryAction: action)
        if let image = data.image {
            button.image = UIImage(systemName: image)
        }
        viewController?.navigationItem.rightBarButtonItem = button
    }

    private func disconnect() {
        let viewController = delegate.destination as? UIViewController
        viewController?.navigationItem.rightBarButtonItem = nil
    }
}

private extension ButtonComponent {
    struct MessageData: Decodable {
        let title: String
        let image: String?
    }
}
