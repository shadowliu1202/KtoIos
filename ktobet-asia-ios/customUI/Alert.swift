//
//  AlertView.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/17.
//

import Foundation
import UIKit

class Alert{
        
    class func show(_ title: String?, _ message : String?, confirm: (()->Void)?, cancel:(()->Void)? ){
        if let topVc = UIApplication.shared.keyWindow?.topViewController{
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Localize.string("Determine"), style: .default) { (action) in
                confirm?()
            })
            if cancel != nil{
                alert.addAction(UIAlertAction(title: Localize.string("Cancel"), style: .cancel) { (action) in
                    cancel?()
                })
            }
            topVc.present(alert, animated: true, completion: nil)
        }
    }
}
