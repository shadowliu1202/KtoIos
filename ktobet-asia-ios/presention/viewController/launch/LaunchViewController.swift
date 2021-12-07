import UIKit
import RxSwift
import SharedBu

class LaunchViewController : UIViewController{
    private var viewModel = DI.resolve(LaunchViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.initLocale().andThen(self.viewModel.checkIsLogged())
            .subscribe { (isLogged) in
                self.nextPage(isLogged: isLogged)
            } onError: { (error) in
                self.nextPage(isLogged: false)
            }.disposed(by: disposeBag)
    }
    
    func nextPage(isLogged: Bool) {
        CustomServicePresenter.shared.observeCustomerService().observeOn(MainScheduler.asyncInstance).subscribe(onCompleted: {
            print("Completed")
        }).disposed(by: disposeBag)
        
        if isLogged {
            self.viewModel.initLocale().andThen(self.viewModel.loadPlayerInfo()).subscribe { (player) in
                NavigationManagement.sharedInstance.goTo(productType: player.defaultProduct)
            } onError: { (error) in
                NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
            }.disposed(by: disposeBag)
        } else {
            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
        }
    }
    
    deinit {
        print("deinit")
    }
}
