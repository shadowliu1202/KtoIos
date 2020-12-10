//
//  RegisterViewController.swift
//  KtoPra
//
//  Created by Partick Chen on 2020/10/21.
//

import UIKit
import RxSwift
import RxCocoa
import share_bu
import Swinject

class SignupUserinfoViewController: UIViewController {
        
    enum AccountType{
        case phone
        case email
    }
    
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var btnSubmit: UIButton!
    @IBOutlet private weak var btnPhone: UIButton!
    @IBOutlet private weak var btnEmail: UIButton!
    
    @IBOutlet private weak var labAccount : UILabel!
    @IBOutlet private weak var labAccountTip : UILabel!
    @IBOutlet private weak var labName : UILabel!
    @IBOutlet private weak var labNameTip : UILabel!
    @IBOutlet private weak var labPassword : UILabel!
    @IBOutlet private weak var labPsConfirm : UILabel!
    @IBOutlet private weak var labPasswordTip : UILabel!
    
    @IBOutlet private weak var textAccount: UITextField!
    @IBOutlet private weak var textName: UITextField!
    @IBOutlet private weak var textPassword: UITextField!
    @IBOutlet private weak var textPsConfirm: UITextField!
    
    @IBOutlet private weak var viewEmail: UIView!
    @IBOutlet private weak var viewName: UIView!
    @IBOutlet private weak var viewPassword: UIView!
    @IBOutlet private weak var viewMainten : UIView!
    @IBOutlet private weak var underlinePhone : UIView!
    @IBOutlet private weak var underlineEmail : UIView!
    
    private let segueLanguage = "BackToLanguageList"
    private let seguePhone = "GoToPhone"
    private let segueEmail = "GoToEmail"
    
    private var viewModel = DI.resolve(SignupUserInfoViewModel.self)!
    private var disposeBag = DisposeBag()
    var locale : SupportLocale?
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        for view in [viewEmail, viewName, viewPassword]{
            view?.layer.masksToBounds = true
            view?.layer.borderWidth = 0.5
            view?.layer.borderColor = UIColor.lightGray.cgColor
            view?.layer.cornerRadius = 4
        }
        setViewModel()
    }
    
    // MARK: METHOD
    func setViewModel(){
        
        (textName.rx.text.orEmpty <-> viewModel.name).disposed(by: disposeBag)
        (textAccount.rx.text.orEmpty <-> viewModel.account).disposed(by: disposeBag)
        (textPassword.rx.text.orEmpty <-> viewModel.password).disposed(by: disposeBag)
        viewModel.locale = locale ?? SupportLocale.China()
        
        let output = viewModel.output()
        
        output.nameValid.subscribe(onNext: {valid in
            self.labNameTip.text = valid ? "" : "請輸入正確的姓名"
        }).disposed(by: disposeBag)


        output.accountValid.subscribe(onNext: {result in
            switch result.type{
            case .email: self.labAccountTip.text = result.valid ? "" : "請輸入正確的信箱"
            case .phone: self.labAccountTip.text = result.valid ? "" : "請輸入正確的電話"
            }
        }).disposed(by: disposeBag)

        output.passwordValid.subscribe(onNext: {valid in
            self.labPasswordTip.text = valid ? "" : "請輸入正確的密碼"
        }).disposed(by: disposeBag)
        
        output.typeChange.subscribe(onNext: {type in
            switch type {
            case .phone:
                self.labAccount.text = "手机"
                self.textAccount.text = ""
                self.textAccount.keyboardType = .numberPad
                self.btnPhone.isSelected = true
                self.btnEmail.isSelected = false
                self.underlinePhone.backgroundColor = UIColor(rgb: 0xf20000)
                self.underlineEmail.backgroundColor = UIColor(rgb: 0x202020)
            case .email:
                self.labAccount.text = "电子邮箱"
                self.textAccount.text = ""
                self.textAccount.keyboardType = .emailAddress
                self.btnPhone.isSelected = false
                self.btnEmail.isSelected = true
                self.underlinePhone.backgroundColor = UIColor(rgb: 0x202020)
                self.underlineEmail.backgroundColor = UIColor(rgb: 0xf20000)
            }
        }).disposed(by: disposeBag)

        output.dataValid.bind(to: btnSubmit.rx.isEnabled).disposed(by: disposeBag)
    }
}

extension SignupUserinfoViewController{
    // MARK: PAGE ACTION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? SignupEmailViewController {
            vc.account = viewModel.account.value
            vc.password = viewModel.password.value
        }
    }
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
    @IBAction func backToUserInfo(segue : UIStoryboardSegue){}
}

extension SignupUserinfoViewController{
    // MARK: BUTTON ACTION
    @IBAction func btnPhonePressed(_ sender : Any){
        viewModel.typeChange(.phone)
    }
    
    @IBAction func btnEmailPressed(_ sender : Any){
        viewModel.typeChange(.email)
    }
    
    @IBAction func btnBackPressed(_ sender : Any){
        performSegue(withIdentifier: segueLanguage, sender: nil)
    }
    
    @IBAction func btnSubmitPressed(_ sender : Any){
        
        let result = viewModel.register()
        let segue = result.type == .email ? segueEmail : seguePhone
        result.completable
            .subscribe(onCompleted: {
                self.performSegue(withIdentifier: segue, sender: nil)
            }, onError: {error in
                
            }).disposed(by: disposeBag)
    }
}
