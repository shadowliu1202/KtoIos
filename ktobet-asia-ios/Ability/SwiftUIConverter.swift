import SwiftUI
import UIKit

protocol SwiftUIConverter: UIViewController { }

extension SwiftUIConverter {
  func addSubView<Content>(
    _ swiftUIView: Content,
    to _: UIView,
    configure: ((UIHostingController<Content>) -> Void)? = nil) where Content: View
  {
    let hostingController = embedHosting(swiftUIView)
    configure?(hostingController)
  }

  /// Use factory to init  *@StateObject*
  /// Make sure to use unretain self
  func addSubView<Content>(
    from factory: () -> Content,
    to _: UIView,
    configure: ((UIHostingController<Content>) -> Void)? = nil) where Content: View
  {
    let hostingController = embedHosting(factory())
    configure?(hostingController)
  }

  func addAsContainer(at controller: UIViewController) {
    controller.addChild(self)

    controller.view.addSubview(view)
    view.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    didMove(toParent: controller)
  }

  private func embedHosting
  <Content: View>
  (_ content: Content)
    -> UIHostingController<Content>
  {
    let hostingController = UIHostingController(rootView: content)
    hostingController.view.backgroundColor = .clear

    addChild(hostingController)

    view.insertSubview(hostingController.view, at: 0)
    hostingController.view.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    hostingController.didMove(toParent: self)

    return hostingController
  }
}
