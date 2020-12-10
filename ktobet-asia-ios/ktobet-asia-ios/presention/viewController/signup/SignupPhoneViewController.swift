//
//  Register3ViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/29.
//

import UIKit
import RxSwift
import RxCocoa
import share_bu

class SignupPhoneViewController: UIViewController {

    @IBOutlet private weak var labDesc1: UILabel!
    @IBOutlet private weak var labDesc2: UILabel!
    
    @IBOutlet private weak var textCode1: UITextField!
    @IBOutlet private weak var textCode2: UITextField!
    @IBOutlet private weak var textCode3: UITextField!
    @IBOutlet private weak var textCode4: UITextField!
    @IBOutlet private weak var textCode5: UITextField!
    @IBOutlet private weak var textCode6: UITextField!
    
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var btnVerify: UIButton!
    @IBOutlet private weak var btnResend: UIButton!
    
    private let segueUserInfo = "BackToUserInfo"
    private var disposeBag = DisposeBag()
    private var viewModel = DI.resolve(SignupPhoneViewModel.self)!
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let arrText = [self.textCode1, self.textCode2, self.textCode3, self.textCode4, self.textCode5, self.textCode6]
        for text in arrText {
            text?.textContentType = .oneTimeCode
            text?.rx.text.orEmpty.subscribe(onNext: {text in
                if text.count == 6{
                    let arrChar = Array(text)
                    for idx in 0...5{
                        arrText[idx]?.text = String(arrChar[idx])
                        arrText[idx]?.resignFirstResponder()
                    }
                }
            }).disposed(by: disposeBag)
        }

        (textCode1.rx.text.orEmpty <-> viewModel.code1).disposed(by: disposeBag)
        (textCode2.rx.text.orEmpty <-> viewModel.code2).disposed(by: disposeBag)
        (textCode3.rx.text.orEmpty <-> viewModel.code3).disposed(by: disposeBag)
        (textCode4.rx.text.orEmpty <-> viewModel.code4).disposed(by: disposeBag)
        (textCode5.rx.text.orEmpty <-> viewModel.code5).disposed(by: disposeBag)
        (textCode6.rx.text.orEmpty <-> viewModel.code6).disposed(by: disposeBag)
    }
    
    // MARK: BUTTON EVENT
    @IBAction func btnBackPressed(_ sender : Any){
        performSegue(withIdentifier: segueUserInfo, sender: nil)
    }
    
    @IBAction func btnVerifyPressed(_ sender : Any){
        viewModel.otpVerify()
            .subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: {player in
                self.goToLobby(player)
            }, onError: {error in
                
            }).disposed(by: disposeBag)
    }
    
    // MARK: PAGE ACTION
    private func goToLobby(_ player : Player){
        let storyboard = UIStoryboard(name: "Lobby", bundle: nil)
        if let initVc = storyboard.instantiateInitialViewController() as? UINavigationController,
           let lobby = initVc.viewControllers.first as? LobbyViewController {
            lobby.player = player
            UIApplication.shared.keyWindow?.rootViewController = initVc
        }
    }
}

extension SignupPhoneViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
}
