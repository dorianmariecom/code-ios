import HotwireNative
import UIKit

class TabBarComponent: BridgeComponent {
    override class var name: String { "tab-bar" }

    override func onReceive(message: Message) {
        if message.event == "connect" {
            guard let data: MessageData = message.data() else { return }

            let newTabs = data.tabs.map(\.definition)
            let sourceURL = message.metadata.flatMap { URL(string: $0.url) }

            if newTabs.isEmpty || newTabs == AppTab.definitions {
                return
            }

            AppConfig.sceneDelegate?.updateTabs(newTabs, from: sourceURL)
        }
    }
    
    struct MessageData: Decodable {
        let tabs: [MessageTab]
    }

    struct MessageTab: Decodable {
        let title: String
        let image: String
        let path: String

        var definition: AppTabDefinition {
            AppTabDefinition(
                title: title,
                imageSystemName: image,
                path: path
            )
        }
    }
}
