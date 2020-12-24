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
        let type = ErrorType(rawValue: (error as NSError).code)
        if type == .ApiUnknownException{
            let message = String(format: Localize.string("UnknownError"), "\((error as NSError).code)")
            Alert.show(nil, message, confirm: nil, cancel: nil)
        } else if let message = (error as NSError).userInfo["errorMsg"] as? String{
            Alert.show(nil, message, confirm: nil, cancel: nil)
        } else {
            Alert.show(nil, error.localizedDescription, confirm: nil, cancel: nil)
        }
    }
}
