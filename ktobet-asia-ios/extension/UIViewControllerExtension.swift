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
import Moya
import SharedBu

extension UIViewController{
    func handleErrors(_ error : Error) {
        let exception = ExceptionFactory.create(error)
        if exception is ApiUnknownException {
            handleUnknownError(error)
        } else if let errorMsg = exception.message {
            showAlertError(errorMsg)
        } else {
            handleUnknownError(error)
        }
    }
    
    func handleUnknownError(_ error : Error) {
        let unknownErrorString = String(format: Localize.string("common_unknownerror"), "\((error as NSError).code)")
        guard let error = error as? MoyaError else {
            showAlertError(unknownErrorString)
            return
        }
        
        switch error {
        case .statusCode(let response):
            handleHttpError(error, response: response)
        case .underlying:
            showAlertError("尚未连线网路")
        case .jsonMapping, .encodableMapping, .imageMapping, .objectMapping:
            showAlertError("格式错误")
        default:
            showAlertError(unknownErrorString)
        }
    }
    
    private func handleHttpError(_ error: Error,  response: Response) {
        switch response.statusCode {
        case 401:
            let disposeBag = DisposeBag()
            let viewModel = DI.resolve(PlayerViewModel.self)!
            viewModel.logout()
                .subscribeOn(MainScheduler.instance)
                .subscribe(onCompleted: {
                    NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
                }).disposed(by: disposeBag)
        case 410:
            showAlertError("系统维护中")
        case 404:
            showAlertError(String(format: Localize.string("common_unknownerror"), "\(response.statusCode)"))
        default:
            showAlertError(String(format: Localize.string("common_unknownerror"), "\(response.statusCode)"))
        }
    }
    
    private func showAlertError(_ content: String) {
        let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
        toastView.show(on: nil, statusTip: content, img: UIImage(named: "Failed"))
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
    
    func showToast(_ popUp: ToastPopUp) {
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
    var isVisible: Observable<Bool> {
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
