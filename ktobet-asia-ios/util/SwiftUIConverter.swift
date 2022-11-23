import SwiftUI
import UIKit

protocol SwiftUIConverter: UIViewController { }

extension SwiftUIConverter {
    
    func addSubView<Content>(
        _ swiftUIView: Content,
        to view: UIView,
        configure: ((UIHostingController<Content>) -> Void)? = nil
    ) where Content : View {
        
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.backgroundColor = .clear
        
        addChild(hostingController)
        
        view.addSubview(hostingController.view)
        hostingController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        hostingController.didMove(toParent: self)
        
        configure?(hostingController)
    }
}
