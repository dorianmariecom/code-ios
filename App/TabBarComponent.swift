import HotwireNative
import UIKit

class TabBarComponent: BridgeComponent {
    override class var name: String { "tab-bar" }

    override func onReceive(message: Message) {
        if message.event == "connect" {
            guard let data: MessageData = message.data() else { return }

            let newTabs = data.tabs.map { tab in
                HotwireTab(
                    title: tab.title,
                    image: UIImage(systemName: tab.image)!,
                    url: AppConfig.baseURL.appending(path: tab.path)
                )
            }

            if (newTabs.isEmpty || newTabs == HotwireTab.all) {
                return
            }

            HotwireTab.all = newTabs

            AppConfig.sceneDelegate?.viewDidLoad()
        }
    }

    struct MessageTab: Decodable {
        let title: String
        let image: String
        let path: String
    }

    struct MessageData: Decodable {
        let tabs: [MessageTab]
    }
}
