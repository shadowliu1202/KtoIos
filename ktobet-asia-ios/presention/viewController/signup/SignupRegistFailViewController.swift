//
//  SignupRegistFailViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/22.
//

import Foundation
import UIKit

class SignupRegistFailViewController : UIViewController{
    static let segueIdentifier = "GoToFail"
    @IBOutlet private weak var naviItem : UINavigationItem!
    @IBOutlet private weak var imgFailIcon : UIImageView!
    @IBOutlet private weak var labTitle : UILabel!
    @IBOutlet private weak var labDesc : UILabel!
    @IBOutlet private weak var btnRestart : UIButton!
    
    var failedType: FailedType = .register
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localize()
        defaultStyle()
    }
    
    // MARK: METHOD
    private func localize(){
        switch failedType {
        case .register:
            labTitle.text = Localize.string("register_step4_title_fail")
            labDesc.text = Localize.string("register_step4_content_fail")
            btnRestart.setTitle(Localize.string("register_step4_retry_signup"), for: .normal)
        case .resetPassword:
            labTitle.text = Localize.string("login_resetpassword_fail_title")
            labDesc.text = ""
            btnRestart.setTitle(Localize.string("common_back"), for: .normal)
        }
    }
    
    private func defaultStyle(){
        naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
        btnRestart.layer.cornerRadius = 9
        btnRestart.layer.masksToBounds = true
    }
    
    @IBAction private func btnRestartPressed(_ sender : UIButton){
        switch failedType {
        case .register:
            self.navigationController?.popToRootViewController(animated: true)
        case .resetPassword:
            self.dismiss(animated: true, completion: nil)
        }
    }
}


enum FailedType {
    case register
    case resetPassword
}
