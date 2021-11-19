//
//  SignupRegistFailViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/22.
//

import Foundation
import UIKit
import RxSwift

class SignupRegistFailViewController : UIViewController{
    static let segueIdentifier = "GoToFail"
    var barButtonItems: [UIBarButtonItem] = []
    
    @IBOutlet private weak var naviItem : UINavigationItem!
    @IBOutlet private weak var imgFailIcon : UIImageView!
    @IBOutlet private weak var labTitle : UILabel!
    @IBOutlet private weak var labDesc : UILabel!
    @IBOutlet private weak var btnRestart : UIButton!
    @IBOutlet private weak var scollView : UIScrollView!
    private var padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    private lazy var customService = UIBarButtonItem.kto(.cs(delegate: self, disposeBag: disposeBag))
    
    var failedType: FailedType = .register
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bind(position: .right, barButtonItems: padding, customService)
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
        scollView.backgroundColor = UIColor.black_two
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

extension SignupRegistFailViewController: BarButtonItemable { }

extension SignupRegistFailViewController: CustomServiceDelegate {
    func customServiceBarButtons() -> [UIBarButtonItem]? {
        [padding, customService]
    }
}
