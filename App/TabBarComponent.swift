import HotwireNative
import UIKit

class TabBarComponent: BridgeComponent {
    override class var name: String { "tab-bar" }

    override func onReceive(message: Message) {
        if message.event == "connect" {

            guard let data: MessageData = message.data() else { return }

            let newTabs = data.tabs.map { Tab(title: $0.title, image: $0.image, path: $0.path) }


            if (newTabs.isEmpty || newTabs == Tab.all) {
                return
            }

            Tab.all = newTabs

            let viewController = delegate.destination as? UIViewController
            let tabBarController = viewController?.tabBarController as? TabBarController
            let sceneDelegate = tabBarController?.sceneDelegate as? SceneDelegate
            sceneDelegate?.viewDidLoad()
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
