class Tab: Equatable {
    let title: String
    let image: String
    let path: String

    static var all = [
        Tab(title: "loading...", image: "circle.fill", path: ""),
    ]

    init(title: String, image: String, path: String) {
        self.title = title
        self.image = image
        self.path = path
    }

    static func == (lhs: Tab, rhs: Tab) -> Bool {
        return lhs.title == rhs.title &&
               lhs.image == rhs.image &&
               lhs.path == rhs.path
    }
}
