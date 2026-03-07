import HotwireNative
import UIKit
import WebKit

final class RefreshComponent: BridgeComponent {
    override class var name: String { "refresh" }

    private var viewController: UIViewController? {
        delegate?.destination as? UIViewController
    }

    override func onReceive(message: Message) {
        if message.event == "connect" {
            let action = UIAction { [weak self] _ in
                self?.reloadCurrentWebView()
            }

            guard let viewController else { return }
            let navigationItems = viewController.navigationItems

            navigationItems.buttonItem = nil
            navigationItems.refreshItem = UIBarButtonItem(
                title: "Refresh",
                image: UIImage(systemName: "arrow.clockwise"),
                primaryAction: action
            )

            viewController.navigationItem.rightBarButtonItems = navigationItems.items
        } else if (message.event == "disconnect") {
            guard let viewController else { return }

            let navigationItems = viewController.navigationItems
            navigationItems.refreshItem = nil

            viewController.navigationItem.rightBarButtonItems = navigationItems.items
        }
    }

    private func reloadCurrentWebView() {
        guard let viewController else { return }

        if let navigationController = viewController as? UINavigationController,
           let webView = findWebView(in: navigationController.view) {
            webView.reload()
            return
        }

        findWebView(in: viewController.view)?.reload()
    }

    private func findWebView(in view: UIView?) -> WKWebView? {
        guard let view else { return nil }

        if let webView = view as? WKWebView {
            return webView
        }

        for subview in view.subviews {
            if let webView = findWebView(in: subview) {
                return webView
            }
        }

        return nil
    }
}
