import HotwireNative
import UIKit

class FlashComponent: BridgeComponent {
    override class var name: String { "flash" }

    struct MessageData: Decodable {
        let message: String
        let type: String
    }

    override func onReceive(message: Message) {
        if message.event == "connect" {
            guard
                let data: MessageData = message.data(),
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let window = windowScene.windows.first(where: { $0.isKeyWindow })
            else { return }

            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.backgroundColor = .white
            container.layer.cornerRadius = 12
            container.layer.borderColor = (data.type == "alert" ? UIColor(hex: "#dc2626") : UIColor(hex: "#16a34a")).cgColor
            container.layer.borderWidth = 1
            container.clipsToBounds = true

            let label = makeLabel(data)
            container.addSubview(label)
            constrainLabel(label, in: container)

            window.addSubview(container)
            constrainContainer(container, in: window)

            animateToastInAndOut(container)
        }
    }

    private func makeLabel(_ data: MessageData) -> UILabel {
        let color = data.type == "alert" ? UIColor(hex: "#dc2626") : UIColor(hex: "#16a34a")
        let label = UILabel()
        label.text = data.message
        label.textAlignment = .center
        label.textColor = color
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func constrainLabel(_ label: UILabel, in container: UIView) {
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
    }

    private func constrainContainer(_ container: UIView, in window: UIView) {
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            container.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            container.widthAnchor.constraint(lessThanOrEqualTo: window.widthAnchor, constant: -32)
        ])
    }

    private func animateToastInAndOut(_ view: UIView) {
        UIView.animate(withDuration: 0.3, delay: 5, options: [], animations: {
            view.alpha = 0
        }) { _ in
            view.removeFromSuperview()
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.hasPrefix("#") ? String(hexSanitized.dropFirst()) : hexSanitized

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
