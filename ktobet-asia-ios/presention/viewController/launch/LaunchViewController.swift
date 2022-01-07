import UIKit
import RxSwift
import SharedBu

class LaunchViewController: UIViewController {
    private var viewModel = DI.resolve(LaunchViewModel.self)!
    private var serviceViewModel = DI.resolve(ServiceStatusViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.initLocale().subscribe(onCompleted: { }).disposed(by: disposeBag)
        Observable.combineLatest(serviceViewModel.output.portalMaintenanceStatus.asObservable(), viewModel.checkIsLogged().asObservable())
            .subscribe(onNext: { [weak self] (status, isLogged) in
                switch status {
                case is MaintenanceStatus.AllPortal:
                    self?.setPortalMaintenance()
                case is MaintenanceStatus.Product:
                    if isLogged {
                        self?.nextPage()
                    } else {
                        NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
                    }
                default:
                    break
                }
            }) { [weak self] error in
                self?.handleErrors(error)
            }.disposed(by: disposeBag)
    }
    
    private func nextPage() {
        observeCustomerService()
        let playerDefaultProduct = viewModel.loadPlayerInfo().compactMap{ $0.defaultProduct }.asObservable()
        playerDefaultProduct.bind(to: serviceViewModel.input.playerDefaultProduct).disposed(by: disposeBag)
        serviceViewModel.output.toNextPage.subscribe(onError: {[weak self] error in self?.handleErrors(error) }).disposed(by: disposeBag)
    }
    
    private func observeCustomerService() {
        CustomServicePresenter.shared.observeCustomerService().observeOn(MainScheduler.asyncInstance).subscribe(onCompleted: {
            print("Completed")
        }).disposed(by: disposeBag)
    }
    
    private func setPortalMaintenance() {
        DispatchQueue.main.async {
            let vc = UIStoryboard(name: "Maintenance", bundle: nil).instantiateViewController(withIdentifier: "PortalMaintenanceViewController")
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    deinit {
        print("deinit")
    }
}
