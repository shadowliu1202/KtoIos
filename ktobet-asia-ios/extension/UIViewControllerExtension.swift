import Alamofire
import Foundation
import Moya
import RxCocoa
import RxSwift
import SharedBu
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
    APIErrorHandler(target: self).handle(error)
  }

  func handleMaintenance() {
    let viewModel = Injectable.resolve(PlayerViewModel.self)!
    let disposeBag = DisposeBag()
    let serviceViewModel = Injectable.resolve(ServiceStatusViewModel.self)!

    serviceViewModel.output.portalMaintenanceStatus
      .subscribe(onNext: { status in
        switch status {
        case is MaintenanceStatus.AllPortal:
          if UIApplication.topViewController() is LandingViewController {
            NavigationManagement.sharedInstance.goTo(
              storyboard: "Maintenance",
              viewControllerId: "PortalMaintenanceViewController")
          }
          else {
            viewModel.logout()
              .subscribe(onCompleted: {
                NavigationManagement.sharedInstance.goTo(
                  storyboard: "Maintenance",
                  viewControllerId: "PortalMaintenanceViewController")
              })
              .disposed(by: disposeBag)
          }
        case let productStatus as MaintenanceStatus.Product:
          if let navi = NavigationManagement.sharedInstance.viewController.navigationController as? ProductNavigations {
            let isMaintenance = productStatus.isProductMaintain(productType: navi.productType)
            NavigationManagement.sharedInstance.goTo(productType: navi.productType, isMaintenance: isMaintenance)
          }
        default:
          break
        }
      })
      .disposed(by: disposeBag)
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
