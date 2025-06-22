import HotwireNative
import UIKit

final class ConfirmComponent: BridgeComponent {
    override class var name: String { "confirm" }
    
    struct MessageData: Decodable {
        let title: String
        let description: String?
        let destructive: Bool
        let cancel: String
        let confirm: String
        var confirmActionStyle: UIAlertAction.Style { destructive ? .destructive : .default }
    }

    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    override func onReceive(message: Message) {
        if message.event == "show" {
            guard let data: MessageData = message.data() else { return }

            let alert = UIAlertController(
                title: data.title,
                message: data.description,
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(
                title: data.confirm,
                style: data.confirmActionStyle
            ) { [unowned self] _ in
                reply(to: message.event)
            })

            alert.addAction(UIAlertAction(
                title: data.cancel,
                style: .cancel
            ) { _ in })

            viewController?.present(alert, animated: false)
        }
    }
}
