import HotwireNative
import UIKit

final class SearchComponent: BridgeComponent {
    override class var name: String { "search" }
    
    struct QueryMessageData: Encodable {
        let query: String?
    }

    private let searchController = UISearchController(searchResultsController: nil)
    private lazy var searchResultsUpdater = SearchResultsUpdater(component: self)

    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    override func onReceive(message: Message) {
        if message.event == "connect" {
            addSearchController()
        } else if message.event == "disconnect" {
            removeSearchController()
        }
    }

    private func addSearchController() {
        searchController.searchResultsUpdater = searchResultsUpdater
        viewController?.navigationItem.searchController = searchController
        viewController?.navigationItem.hidesSearchBarWhenScrolling = false
        viewController?.definesPresentationContext = true
    }
    
    private func removeSearchController() {
        viewController?.navigationItem.searchController = nil
    }

    fileprivate func updateSearchResults(with query: String?) {
        let data = QueryMessageData(query: query)
        reply(to: "connect", with: data)
    }
}

private class SearchResultsUpdater: NSObject, UISearchResultsUpdating {
    private unowned let component: SearchComponent

    init(component: SearchComponent) {
        self.component = component
    }

    func updateSearchResults(for searchController: UISearchController) {
        component.updateSearchResults(with: searchController.searchBar.text)
    }
}
