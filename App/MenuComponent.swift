import HotwireNative
import UIKit

final class MenuComponent: BridgeComponent {
    override class var name: String { "menu" }
    
    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    override func onReceive(message: Message) {
        if message.event == "connect" {
            guard let data: MessageData = message.data() else { return }

            var actions = [UIAction]()
            for (index, item) in data.menu.enumerated() {
                let image = UIImage(systemName: item.image ?? "")
                let action = UIAction(title: item.title, image: image) { [unowned self] _ in
                    reply(to: message.event, with: SelectionMessageData(index: index))
                }
                actions.append(action)
            }

            let button = UIBarButtonItem(
                title: "Menu",
                image: UIImage(systemName: "ellipsis"),
                menu: UIMenu(children: actions)
            )

            viewController?.navigationItem.rightBarButtonItem = button
        }
    }

    struct MessageData: Decodable {
        let menu: [Item]
    }

    struct Item: Decodable {
        let title: String
        let image: String?
    }

    struct SelectionMessageData: Encodable {
        let index: Int
    }
}
