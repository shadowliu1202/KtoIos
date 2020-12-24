//
//  SignupRegistFailViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/22.
//

import Foundation
import UIKit

class SignupRegistFailViewController : UIViewController{
    
    @IBOutlet private weak var naviItem : UINavigationItem!
    @IBOutlet private weak var imgFailIcon : UIImageView!
    @IBOutlet private weak var labTitle : UILabel!
    @IBOutlet private weak var labDesc : UILabel!
    @IBOutlet private weak var btnRestart : UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        localize()
        defaultStyle()
    }
    
    // MARK: METHOD
    private func localize(){
        labTitle.text = Localize.string("Step4_Title_Fail")
        labDesc.text = Localize.string("Step4_Content_Fail")
        btnRestart.setTitle(Localize.string("Step4_retry_signup"), for: .normal)
    }
    
    private func defaultStyle(){
        naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
        btnRestart.layer.cornerRadius = 9
        btnRestart.layer.masksToBounds = true
    }
    
    @IBAction private func btnRestartPressed(_ sender : UIButton){
        self.navigationController?.popToRootViewController(animated: true)
    }
    
}
