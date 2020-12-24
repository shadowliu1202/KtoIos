//
//  LaunchViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/18.
//

import UIKit
import RxSwift

class LaunchViewController : UIViewController{
    
    private var viewModel = DI.resolve(LaunchViewModel.self)!
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() ) { [self] in
            self.viewModel
                .checkIsLogged()
                .subscribe(onSuccess: {isLogged in
                    self.nextPage(isLogged: isLogged)
                }, onError: {error in
                    self.nextPage(isLogged: false)
                }).disposed(by: self.disposeBag)
        }
    }
    
    func nextPage(isLogged : Bool){
        
        let story : UIStoryboard = {
            if isLogged { return UIStoryboard.init(name: "Lobby", bundle: nil)}
            else { return UIStoryboard.init(name: "Login", bundle: nil) }
        }()
        if let nav = story.instantiateInitialViewController() as? UINavigationController{
            if nav.viewControllers.first is LobbyViewController ||
               nav.viewControllers.first is LoginViewController{
                UIApplication.shared.keyWindow?.rootViewController = nav
            }
        }
    }
    
    deinit {}
}
