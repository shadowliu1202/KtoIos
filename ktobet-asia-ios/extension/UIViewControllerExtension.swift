//
//  UIViewControllerExtension.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/23.
//

import Foundation
import UIKit
import RxSwift
import Moya

extension UIViewController{
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
        case .jsonMapping, .encodableMapping:
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
        default:
            showAlertError(String(format: Localize.string("common_unknownerror"), "\((error as NSError).code)"))
        }
    }
    
    private func showAlertError(_ content: String) {
        let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
        toastView.show(on: self.view, statusTip: content, img: UIImage(named: "Failed"))
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
