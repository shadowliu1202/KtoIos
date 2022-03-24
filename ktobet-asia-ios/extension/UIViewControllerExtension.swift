//
//  UIViewControllerExtension.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/23.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Alamofire
import Moya
import SharedBu

//MARK: Handle error
extension UIViewController{
    @objc func handleErrors(_ error: Error) {
        switch error {
        case let apiException as ApiException:
            handleStatusCode(Int(apiException.errorCode ?? "0") ?? 0)
        case let moyaError as MoyaError:
            handleMoyaError(moyaError)
        case let afError as AFError:
            handleAFError(afError)
        case let nsError as NSError:
            HandleNSError(nsError)
        default:
            handleUnknownError(error)
        }
    }
    
    private func handleMoyaError(_ error: MoyaError) {
        switch error {
        case .statusCode(let response):
            handleHttpError(response: response)
        case .underlying(let afError, _):
            handleAFError(afError as! AFError)
        case .jsonMapping, .encodableMapping, .imageMapping, .objectMapping:
            showAlertError(Localize.string("common_malformedexception"))
        default:
            handleUnknownError(error)
        }
    }

    private func handleAFError(_ error: AFError) {
        if case .sessionTaskFailed(let err) = error,
            let nsError = err as NSError? {
            HandleNSError(nsError)
        } else if case .explicitlyCancelled = error {
            // do nothing
        } else {
            handleUnknownError(error)
        }
    }

    private func HandleNSError(_ error: NSError) {
        switch error.code {
        case 410:
            self.handleMaintenance()
        case NSURLErrorNetworkConnectionLost,
             NSURLErrorNotConnectedToInternet,
             NSURLErrorCannotConnectToHost,
             NSURLErrorCannotFindHost,
             NSURLErrorTimedOut:
            showAlertError(Localize.string("common_unknownhostexception"))
        default:
            handleUnknownError(error)
            break
        }
    }
    
    private func handleUnknownError(_ error: Error) {
        let unknownErrorString = String(format: Localize.string("common_unknownerror"), "\((error as NSError).code)")
        showAlertError(unknownErrorString)
    }

    private func handleHttpError(response: Response) {
        handleStatusCode(response.statusCode)
    }

    private func handleStatusCode(_ statusCode: Int) {
        switch statusCode {
        case 403:
            showRestrictView()
        case 410:
            handleMaintenance()
        case 404:
            showAlertError(String(format: Localize.string("common_unknownerror"), "\(statusCode)"))
        case 503:
            showAlertError(String(format: Localize.string("common_http_503"), "\(statusCode)"))
        default:
            showAlertError(String(format: Localize.string("common_unknownerror"), "\(statusCode)"))
        }
    }
}

extension UIViewController{
    func handleMaintenance() {
        let viewModel = DI.resolve(PlayerViewModel.self)!
        let disposeBag = DisposeBag()
        let serviceViewModel = DI.resolve(ServiceStatusViewModel.self)!
        serviceViewModel.output.portalMaintenanceStatus.drive(onNext: { [weak self] status in
            switch status {
            case is MaintenanceStatus.AllPortal:
                if UIApplication.topViewController() is LandingViewController {
                    self?.showUnLoginMaintenanAlert()
                } else {
                    viewModel.logout()
                        .subscribeOn(MainScheduler.instance)
                        .subscribe(onCompleted: { [weak self] in
                        self?.showLoginMaintenanAlert()
                    }).disposed(by: disposeBag)
                }
            case let productStatus as MaintenanceStatus.Product:
                if let navi = NavigationManagement.sharedInstance.viewController.navigationController as? ProductNavigations {
                    let isMaintenance = productStatus.isProductMaintain(productType: navi.productType)
                    NavigationManagement.sharedInstance.goTo(productType: navi.productType, isMaintenance: isMaintenance)
                }
                break
            default:
                break
            }
        }).disposed(by: disposeBag)
    }

    func showLoginMaintenanAlert() {
        Alert.show(Localize.string("common_urgent_maintenance"), Localize.string("common_maintenance_logout"), confirm: {
            NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
        }, cancel: nil)
    }

    private func showUnLoginMaintenanAlert() {
        Alert.show(Localize.string("common_maintenance_notify"), Localize.string("common_maintenance_contact_later"), confirm: {
            NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
        }, cancel: nil)
    }

    private func showAlertError(_ content: String) {
        let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
        toastView.show(on: nil, statusTip: content, img: UIImage(named: "Failed"))
    }

    func showRestrictView() {
        let restrictedVC = UIStoryboard(name: "slideMenu", bundle: nil).instantiateViewController(withIdentifier: "restrictedVC")
        self.present(restrictedVC, animated: true, completion: nil)
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
        if let topVc = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.topViewController {
            let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: topVc.view.frame.width, height: 48))
            toastView.show(on: topVc.view, statusTip: msg, img: img)
        }
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
}

/// Reference: https://www.cnblogs.com/strengthen/p/13675147.html
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
