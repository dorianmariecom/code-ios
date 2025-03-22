import HotwireNative
import UIKit

open class VisitableViewController: UIViewController, Visitable {
    public var visitableDelegate: (any HotwireNative.VisitableDelegate)?
    public var visitableView: HotwireNative.VisitableView!
    public var visitableURL: URL!
    
    open func visitableDidRender() {
        navigationItem.title = visitableView.webView?.title
    }
}
