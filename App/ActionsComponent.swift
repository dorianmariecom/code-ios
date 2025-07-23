import HotwireNative
import UIKit

class ActionsComponent: BridgeComponent {
    override class var name: String { "actions" }
    
    struct MessageData: Decodable {
        let categories: [CategoryData]
    }
    
    struct CategoryData: Decodable {
        let identifier: String
        let actions: [ActionData]
    }
    
    struct ActionData: Decodable {
        let identifier: String
        let title: String
        let destructive: Bool
    }
    
    override func onReceive(message: Message) {
        if message.event == "connect" {
            guard let data: MessageData = message.data() else { return }
            
            let categories = data.categories.map { category in
                let actions = category.actions.map { action in
                    UNNotificationAction(
                        identifier: action.identifier,
                        title: action.title,
                        options: action.destructive ? [.destructive] : []
                    )

                }
                
                return UNNotificationCategory(
                    identifier: category.identifier,
                    actions: actions,
                    intentIdentifiers: []
                )
            }

            UNUserNotificationCenter.current().setNotificationCategories(Set(categories))
        }
    }
}
