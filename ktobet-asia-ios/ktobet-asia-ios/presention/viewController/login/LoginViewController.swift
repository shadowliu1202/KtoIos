//
//  LoginViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/23.
//

import UIKit
import RxCocoa
import RxSwift
import share_bu

class LoginViewController: UIViewController {

    @IBOutlet private weak var textAccount : UITextField!
    @IBOutlet private weak var textPassword : UITextField!
    @IBOutlet private weak var btnSignup : UIBarButtonItem!
    @IBOutlet private weak var btnLogin : UIButton!
    
    private let segueSignup = "GoToSignup"
    
    private var disposeBag = DisposeBag()
    private var viewModel = DI.resolve(LoginViewModel.self)!
    var textCaptcha = UITextField()
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        textAccount.text = "aaa@aaa.com"
        textPassword.text = "111111"
        (textAccount.rx.text.orEmpty <-> viewModel.account).disposed(by: disposeBag)
        (textPassword.rx.text.orEmpty <-> viewModel.password).disposed(by: disposeBag)
        (textCaptcha.rx.text.orEmpty <-> viewModel.captcha).disposed(by: disposeBag)
    }
    
    // MARK: BUTTON ACTION
    @IBAction func btnSignupPressed(_ sender : UIButton){
        performSegue(withIdentifier: segueSignup, sender: nil)
    }
    
    @IBAction func btnLoginPressed(_ sender : UIButton){
        viewModel.loginFrom()
            .subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: {player in
                self.goToLobby(player)
            }, onError: {error in
                
            }).disposed(by: disposeBag)
    }
    
    // MARK: PAGE ACTION
    @IBAction func backToLogin(segue: UIStoryboardSegue){}
    private func goToLobby(_ player : Player){
        let storyboard = UIStoryboard(name: "Lobby", bundle: nil)
        if let initVc = storyboard.instantiateInitialViewController() as? UINavigationController,
           let lobby = initVc.viewControllers.first as? LobbyViewController {
            lobby.player = player
            UIApplication.shared.keyWindow?.rootViewController = initVc
        }
    }
}

extension LoginViewController{
    // MARK: PAGE PREPARE
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
}
