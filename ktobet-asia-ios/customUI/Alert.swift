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
            alert.view.backgroundColor = UIColor.white
            alert.view.layer.cornerRadius = 14
            alert.view.clipsToBounds = true
            let confirmAction = UIAlertAction(title: Localize.string("common_confirm"), style: .default) { (action) in
                confirm?()
            }
            
            let cancelction = UIAlertAction(title: Localize.string("common_cancel"), style: .cancel) { (action) in
                cancel?()
            }
            
            cancelction.setValue(UIColor.redForLightFull, forKey: "titleTextColor")
            confirmAction.setValue(UIColor.redForLightFull, forKey: "titleTextColor")
            alert.addAction(confirmAction)
            if cancel != nil{
                alert.addAction(cancelction)
            }
            topVc.present(alert, animated: true, completion: nil)
        }
    }
    
    class func show(_ title: String?, _ message : String?, confirm: (()->Void)?, cancel:(()->Void)?, tintColor: UIColor) {
        if let topVc = UIApplication.shared.keyWindow?.topViewController{
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.view.backgroundColor = UIColor.white
            alert.view.layer.cornerRadius = 14
            alert.view.clipsToBounds = true
            let confirmAction = UIAlertAction(title: Localize.string("common_determine"), style: .default) { (action) in
                confirm?()
            }
            
            let cancelction = UIAlertAction(title: Localize.string("common_cancel"), style: .cancel) { (action) in
                cancel?()
            }
            
            cancelction.setValue(tintColor, forKey: "titleTextColor")
            confirmAction.setValue(tintColor, forKey: "titleTextColor")
            alert.addAction(confirmAction)
            if cancel != nil{
                alert.addAction(cancelction)
            }
            topVc.present(alert, animated: true, completion: nil)
        }
    }
}
