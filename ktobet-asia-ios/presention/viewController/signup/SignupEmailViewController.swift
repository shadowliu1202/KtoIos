//
//  SignupEmailViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/30.
//

import UIKit
import RxSwift
import RxCocoa
import share_bu

class SignupEmailViewController: UIViewController {
    
    @IBOutlet private weak var labDesc1: UILabel!
    @IBOutlet private weak var labDesc2: UILabel!
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var btnOpenMail: UIButton!
    @IBOutlet private weak var btnResend: UIButton!
    
    private let segueUserInfo = "BackToUserInfo"
    private let segueDefault = "GoToDefault"
    
    private var viewModel = DI.resolve(SignupEmailViewModel.self)!
    private var disposebag = DisposeBag()
    
    var account : String = ""
    var password : String = ""
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: BUTTON ACTION
    @IBAction func btnVerifyPressed(_ sender : UIButton){
        viewModel.checkAndLogin(account, password)
            .subscribe(onSuccess: {player in
            self.goToLobby(player)
        }, onError: {error in
            
        }).disposed(by: disposebag)
    }
    
    @IBAction func btnBackPressed(_ sender : UIButton){
        performSegue(withIdentifier: segueUserInfo, sender: nil)
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

extension SignupEmailViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
}
