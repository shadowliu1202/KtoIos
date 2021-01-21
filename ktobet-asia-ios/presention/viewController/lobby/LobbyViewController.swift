//
//  LobbyViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/3.
//

import UIKit
import SideMenu
import share_bu
import RxSwift

class LobbyViewController: UIViewController {

    @IBOutlet private weak var labDesc : UILabel!
    @IBOutlet private weak var btnSideBar : UIBarButtonItem!
    
    private let segueSideMenu = "GoToSideMenu"
    private let segueTest = "GoToGameTest"
    private let segueSocket = "GoToSocket"
    private let segueDefault = "GoToDefault"
    private let disposeBag = DisposeBag()
    private var disposable: Disposable?
    private let viewModel = DI.resolve(LobbyViewModel.self)
    private var systemViewModel = DI.resolve(SystemViewModel.self)!
    var player : Player?
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        
        disposable = systemViewModel.observeSystemMessage().subscribe { (target: Target) in
            switch target {
            case .Kickout:
                Alert.show(Localize.string("common_notify_logout_title"), Localize.string("common_notify_logout_content"), confirm: {
                    self.btnLogoutPressed(UIButton())
                }, cancel: nil)
            case .Balance:
                print("refresh Balance")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel?.checkPlayer(player: player)
            .subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: { player in
                self.player = player
                if self.player?.defaultProduct == ProductType.none{
                    self.performSegue(withIdentifier: self.segueDefault, sender: nil)
                } else {
                    self.displayGameName(self.player!.defaultProduct!)
                }
            }, onError: { error in
                
            }).disposed(by: disposeBag)
    }
    
    // MARK: METHOD
    func displayGameName(_ type : ProductType){
        switch type {
        case .casino: labDesc.text = "casino"
        case .sbk: labDesc.text = "sbk"
        case .slot: labDesc.text = "slot"
        case .numbergame: labDesc.text = "number\ngame"
        case .none: labDesc.text = "none"
        default: break
        }
    }
    
    // MARK: BUTTON ACTION
    @IBAction func btnSideMenuPressed(_ sender : UIButton){
        performSegue(withIdentifier: segueSideMenu, sender: nil)
    }
    
    @IBAction func btnTestPressed(_ sender : UIButton){
        performSegue(withIdentifier: segueTest, sender: nil)
    }
    
    @IBAction func btnSocketTestPressed(_ sender : UIButton){
        performSegue(withIdentifier: segueSocket, sender: nil)
    }
    
    @IBAction func btnLogoutPressed(_ sender : UIButton){
        viewModel?.logout()
            .subscribeOn(MainScheduler.instance)
            .subscribe(onCompleted: {
                self.disposable?.dispose()
                self.backToLogin()
            }, onError: {error in
                
            }).disposed(by: disposeBag)
    }

}

extension LobbyViewController {
    // MARK: PAGE ACTION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? SideMenuNavigationController,
           let sideBar = vc.viewControllers.first as? SideBarViewController{
            vc.menuWidth = view.bounds.width
            sideBar.productDidSelected = {type  in
                self.displayGameName(type)
            }
        }
    }
    @IBAction func backToLobby(segue : UIStoryboardSegue){}
    
    func backToLogin(){
        let story = UIStoryboard(name: "Login", bundle: nil)
        UIApplication.shared.keyWindow?.rootViewController = story.instantiateInitialViewController()
    }
}
