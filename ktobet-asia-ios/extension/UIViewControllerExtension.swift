//
//  UIViewControllerExtension.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/23.
//

import Foundation
import UIKit
import RxSwift

extension UIViewController{

    func handleUnknownError(_ error : Error){
        if (error as NSError).code == 5 {
            let disposeBag = DisposeBag()
            let viewModel = DI.resolve(PlayerViewModel.self)!
            viewModel.logout()
                .subscribeOn(MainScheduler.instance)
                .subscribe(onCompleted: {
                    NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
                }).disposed(by: disposeBag)
        }
        let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
        toastView.show(on: self.view, statusTip: String(format: Localize.string("common_unknownerror"), "\((error as NSError).code)"), img: UIImage(named: "Failed"))
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
}
