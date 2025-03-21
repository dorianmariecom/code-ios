import HotwireNative
import UIKit

class CsrfTokenComponent: BridgeComponent {
    override class var name: String { "csrf-token" }

    override func onReceive(message: Message) {
        if message.event == "connect" {
            guard let data: MessageData = message.data() else { return }
            
            AppConfig.csrfToken = data.csrf_token
        }
    }

    struct MessageData: Decodable {
        let csrf_token: String
    }
}
