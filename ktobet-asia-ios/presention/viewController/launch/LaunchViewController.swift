import UIKit
import RxSwift
import share_bu

class LaunchViewController : UIViewController{
    
    private var viewModel = DI.resolve(LaunchViewModel.self)!
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() ) { [self] in
            self.viewModel
                .checkIsLogged()
                .subscribe { (isLogged) in
                    self.nextPage(isLogged: isLogged)
                } onError: { (error) in
                    self.nextPage(isLogged: false)
                }.disposed(by: disposeBag)
        }
    }
    
    func nextPage(isLogged : Bool){
        if isLogged {
            viewModel.loadPlayerInfo().subscribe { (player) in
                switch player.defaultProduct {
                case ProductType.casino:
                    print("Go to casino")
                case ProductType.sbk:
                    NavigationManagement.sharedInstance.goTo(storyboard: "Game", viewControllerId: "SBKNavigationController")
                case ProductType.slot:
                    print("Go to slot")
                case ProductType.numbergame:
                    NavigationManagement.sharedInstance.goTo(storyboard: "Game", viewControllerId: "NumberGameNavigationController")
                default:
                    NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "DefaultProductNavigationViewController")
                }
            } onError: { (error) in
                NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
            }.disposed(by: disposeBag)
        } else {
            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
        }
    }
    
    deinit {}
}
