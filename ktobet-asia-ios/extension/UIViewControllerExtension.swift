//
//  UIViewControllerExtension.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/23.
//

import Foundation
import UIKit

extension UIViewController{
    
    func handleUnknownError(_ error : Error){
        let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
        toastView.show(on: self.view, statusTip: String(format: Localize.string("common_unknownerror"), "\((error as NSError).code)"), img: UIImage(named: "Failed"))
    }
}
