import Foundation
import UIKit
import RxSwift
import RxCocoa
import Alamofire
import Moya
import SharedBu

extension UIViewController {

    @objc func handleErrors(_ error: Error) {
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
                        NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
                    }
                    else {
                        viewModel.logout()
                            .subscribe(onCompleted: {
                                NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
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
    
    func showToastOnBottom(_ msg: String, img: UIImage?) {
        let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
        toastView.show(on: nil, statusTip: msg, img: img)
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
        }, completion: { complete in
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
        creator: ((NSCoder) -> UIViewController?)? = nil
    ) -> Self {
        
        let storyboard = UIStoryboard(name: storyboard, bundle: nil)
        let id = String(describing: self)
        return storyboard.instantiateViewController(identifier: id, creator: creator) as! Self
    }
}

// MARK: - Rx
// Reference: https://www.cnblogs.com/strengthen/p/13675147.html
public extension Reactive where Base: UIViewController {
    var viewDidLoad: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.viewDidLoad)).map { _ in }
        return ControlEvent(events: source)
    }
    var viewWillAppear: ControlEvent<Bool> {
        let source = self.methodInvoked(#selector(Base.viewWillAppear))
            .map { $0.first as? Bool ?? false }
        return ControlEvent(events: source)
    }
    var viewDidAppear: ControlEvent<Bool> {
        let source = self.methodInvoked(#selector(Base.viewDidAppear))
            .map { $0.first as? Bool ?? false }
        return ControlEvent(events: source)
    }
    var viewWillDisappear: ControlEvent<Bool> {
        let source = self.methodInvoked(#selector(Base.viewWillDisappear))
            .map { $0.first as? Bool ?? false }
        return ControlEvent(events: source)
    }
    var viewDidDisappear: ControlEvent<Bool> {
        let source = self.methodInvoked(#selector(Base.viewDidDisappear))
            .map { $0.first as? Bool ?? false }
        return ControlEvent(events: source)
    }
    var viewWillLayoutSubviews: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.viewWillLayoutSubviews))
            .map { _ in }
        return ControlEvent(events: source)
    }
    var viewDidLayoutSubviews: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.viewDidLayoutSubviews))
            .map { _ in }
        return ControlEvent(events: source)
    }
    var willMoveToParentViewController: ControlEvent<UIViewController?> {
        let source = self.methodInvoked(#selector(Base.willMove))
            .map { $0.first as? UIViewController }
        return ControlEvent(events: source)
    }
    var didMoveToParentViewController: ControlEvent<UIViewController?> {
        let source = self.methodInvoked(#selector(Base.didMove))
            .map { $0.first as? UIViewController }
        return ControlEvent(events: source)
    }
    var didReceiveMemoryWarning: ControlEvent<Void> {
        let source = self.methodInvoked(#selector(Base.didReceiveMemoryWarning))
            .map { _ in }
        return ControlEvent(events: source)
    }
    var isVisible: RxSwift.Observable<Bool> {
        let viewDidAppearObservable = self.base.rx.viewDidAppear.map { _ in true }
        let viewWillDisappearObservable = self.base.rx.viewWillDisappear
            .map { _ in false }
        return Observable<Bool>.merge(viewDidAppearObservable,
                                      viewWillDisappearObservable)
    }
    var isDismissing: ControlEvent<Bool> {
        let source = self.sentMessage(#selector(Base.dismiss))
            .map { $0.first as? Bool ?? false }
        return ControlEvent(events: source)
    }
}
