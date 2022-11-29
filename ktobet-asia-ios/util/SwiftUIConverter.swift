import SwiftUI
import UIKit

protocol SwiftUIConverter: UIViewController { }

extension SwiftUIConverter {
    
    func addSubView<Content>(
        _ swiftUIView: Content,
        to view: UIView,
        configure: ((UIHostingController<Content>) -> Void)? = nil
    ) where Content : View {
        
        let hostingController = embedHosting(swiftUIView)
        configure?(hostingController)
    }
    
    /// Use factory to init  *@StateObject*
    /// Make sure to use unretain self
    func addSubView<Content>(
        from factory: () -> Content,
        to view: UIView,
        configure: ((UIHostingController<Content>) -> Void)? = nil
    ) where Content : View {
        
        let hostingController = embedHosting(factory())
        configure?(hostingController)
    }
    
    private func embedHosting
        <Content: View>
        (_ content: Content)
        -> UIHostingController<Content>
    {
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear
        
        addChild(hostingController)
        
        view.addSubview(hostingController.view)
        hostingController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        hostingController.didMove(toParent: self)
        
        return hostingController
    }
}
