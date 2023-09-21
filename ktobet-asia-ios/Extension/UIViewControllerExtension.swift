import Alamofire
import Foundation
import Moya
import RxCocoa
import RxSwift
import SharedBu
import SwiftUI
import UIKit

extension UIViewController {
  enum SnackBarStyle {
    case success
    case failed

    var image: UIImage? {
      switch self {
      case .success:
        return UIImage(named: "Success")
      case .failed:
        return UIImage(named: "Failed")
      }
    }
  }

  @objc
  func handleErrors(_ error: Error) {
    let error = APPError.convert(by: error)
    
    switch error {
    case .unknown(let nsError):
      Logger.shared.error(nsError)
      handleUnknownError(nsError.code)
      
    case .regionRestricted: presentRestrictView()
    case .tooManyRequest: showTooManyRequest()
    case .temporary: showTemporaryError()
    case .cdn: presentCDNErrorView()
    case .maintenance: handleMaintenance()
    case .wrongFormat: showWrongFormat()
    case .ignorable: break
    }
  }
  
  func handleUnknownError(_ statusCode: Int) {
    if statusCode.isNetworkConnectionLost() {
      showToast(Localize.string("common_unknownhostexception"), barImg: .failed)
    }
    else {
      showToast(Localize.string("common_unknownerror", "\(statusCode)"), barImg: .failed)
    }
  }

  func presentRestrictView() {
    let restrictedVC = UIStoryboard(name: "slideMenu", bundle: nil).instantiateViewController(withIdentifier: "restrictedVC")
    present(restrictedVC, animated: true, completion: nil)
  }

  func showTooManyRequest() {
    showToast(Localize.string("common_retry_later"), barImg: nil)
  }

  func showWrongFormat() {
    showToast(Localize.string("common_malformedexception"), barImg: .failed)
  }

  func showTemporaryError() {
    showToast(Localize.string("common_http_503", "\(503)"), barImg: .failed)
  }

  func presentCDNErrorView() {
    let cndErrorVC = UIStoryboard(name: "slideMenu", bundle: nil)
      .instantiateViewController(withIdentifier: "CDNErrorViewController")
    present(cndErrorVC, animated: true, completion: nil)
  }

  func handleMaintenance() {
    @Injected var maintenanceViewModel: MaintenanceViewModel
    @Injected var customerServiceViewModel: CustomerServiceViewModel
    
    _Concurrency.Task { [maintenanceViewModel, customerServiceViewModel] in
      async let maintenanceStatus = maintenanceViewModel.pullMaintenanceStatus()
      async let isPlayerInChat = customerServiceViewModel.isPlayerInChat.first().value
      
      guard
        await maintenanceStatus is MaintenanceStatus.AllPortal,
        let isPlayerInChat = try? await isPlayerInChat
      else { return }
      
      if isPlayerInChat {
        try? await CustomServicePresenter.shared.closeService().value
        
        Alert.shared.show(
          Localize.string("common_maintenance_notify"),
          Localize.string("common_maintenance_chat_close"),
          confirm: {
            NavigationManagement.sharedInstance.goTo(
              storyboard: "Maintenance",
              viewControllerId: "PortalMaintenanceViewController")
          },
          cancel: nil)
      }
      else {
        NavigationManagement.sharedInstance.goTo(
          storyboard: "Maintenance",
          viewControllerId: "PortalMaintenanceViewController")
      }
    }
  }

  func startActivityIndicator(activityIndicator: UIActivityIndicatorView) {
    DispatchQueue.main.async {
      self.view.isUserInteractionEnabled = false
      activityIndicator.startAnimating()
    }
  }

  func stopActivityIndicator(activityIndicator: UIActivityIndicatorView) {
    DispatchQueue.main.async {
      self.view.isUserInteractionEnabled = true
      activityIndicator.stopAnimating()
    }
  }

  func showToast(_ msg: String, barImg: SnackBarStyle?) {
    @Injected var snackBar: SnackBar
    snackBar.show(tip: msg, image: barImg?.image)
  }

  func showToastOnCenter(_ popUp: ToastPopUp) {
    // Make suer there is no any toast showing on the screen
    self.hideToast()

    popUp.tag = 6666
    self.view.addSubview(popUp, constraints: [
      .equal(\.centerXAnchor),
      .equal(\.centerYAnchor)
    ])

    UIView.animate(withDuration: 2.0, delay: 2.0, animations: {
      popUp.alpha = 0.0
    }, completion: { _ in
      popUp.removeFromSuperview()
    })
  }

  func hideToast() {
    for view in self.view.subviews {
      if view is ToastPopUp, view.tag == 6666 {
        view.removeFromSuperview()
      }
    }
  }

  func addChildViewController(_ viewController: UIViewController, inner containView: UIView) {
    addChild(viewController)
    containView.addSubview(viewController.view)
    viewController.view.frame = containView.bounds
    viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    viewController.didMove(toParent: self)
  }

  func removeChildViewController(_ viewController: UIViewController) {
    viewController.willMove(toParent: nil)
    viewController.view.removeFromSuperview()
    viewController.removeFromParent()
  }

  static func initFrom(
    storyboard: String,
    creator: ((NSCoder) -> UIViewController?)? = nil)
    -> Self
  {
    let storyboard = UIStoryboard(name: storyboard, bundle: nil)
    let id = String(describing: self)
    return storyboard.instantiateViewController(identifier: id, creator: creator) as! Self
  }
}

// MARK: - Rx
// Reference: https://www.cnblogs.com/strengthen/p/13675147.html
extension Reactive where Base: UIViewController {
  public var viewDidLoad: ControlEvent<Void> {
    let source = self.methodInvoked(#selector(Base.viewDidLoad)).map { _ in }
    return ControlEvent(events: source)
  }

  public var viewWillAppear: ControlEvent<Bool> {
    let source = self.methodInvoked(#selector(Base.viewWillAppear))
      .map { $0.first as? Bool ?? false }
    return ControlEvent(events: source)
  }

  public var viewDidAppear: ControlEvent<Bool> {
    let source = self.methodInvoked(#selector(Base.viewDidAppear))
      .map { $0.first as? Bool ?? false }
    return ControlEvent(events: source)
  }

  public var viewWillDisappear: ControlEvent<Bool> {
    let source = self.methodInvoked(#selector(Base.viewWillDisappear))
      .map { $0.first as? Bool ?? false }
    return ControlEvent(events: source)
  }

  public var viewDidDisappear: ControlEvent<Bool> {
    let source = self.methodInvoked(#selector(Base.viewDidDisappear))
      .map { $0.first as? Bool ?? false }
    return ControlEvent(events: source)
  }

  public var viewWillLayoutSubviews: ControlEvent<Void> {
    let source = self.methodInvoked(#selector(Base.viewWillLayoutSubviews))
      .map { _ in }
    return ControlEvent(events: source)
  }

  public var viewDidLayoutSubviews: ControlEvent<Void> {
    let source = self.methodInvoked(#selector(Base.viewDidLayoutSubviews))
      .map { _ in }
    return ControlEvent(events: source)
  }

  public var willMoveToParentViewController: ControlEvent<UIViewController?> {
    let source = self.methodInvoked(#selector(Base.willMove))
      .map { $0.first as? UIViewController }
    return ControlEvent(events: source)
  }

  public var didMoveToParentViewController: ControlEvent<UIViewController?> {
    let source = self.methodInvoked(#selector(Base.didMove))
      .map { $0.first as? UIViewController }
    return ControlEvent(events: source)
  }

  public var didReceiveMemoryWarning: ControlEvent<Void> {
    let source = self.methodInvoked(#selector(Base.didReceiveMemoryWarning))
      .map { _ in }
    return ControlEvent(events: source)
  }

  public var isVisible: RxSwift.Observable<Bool> {
    let viewDidAppearObservable = self.base.rx.viewDidAppear.map { _ in true }
    let viewWillDisappearObservable = self.base.rx.viewWillDisappear
      .map { _ in false }
    return Observable<Bool>.merge(
      viewDidAppearObservable,
      viewWillDisappearObservable)
  }

  public var isDismissing: ControlEvent<Bool> {
    let source = self.sentMessage(#selector(Base.dismiss))
      .map { $0.first as? Bool ?? false }
    return ControlEvent(events: source)
  }
}

extension UIViewController {
  // MARK: - Add SwiftUI View
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
