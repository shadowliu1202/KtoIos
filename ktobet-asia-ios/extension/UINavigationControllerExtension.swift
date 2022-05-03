//
//  UINavigationControllerExtension.swift
//  ktobet-asia-ios
//
//  Created by Patrick.chen on 2021/1/22.
//

import UIKit


extension UINavigationController {
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationBar.shadowImage = UIImage()
    }
    
}


