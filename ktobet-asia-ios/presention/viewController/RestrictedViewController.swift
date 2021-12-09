import UIKit
import SharedBu
import RxSwift

class RestrictedViewController: UIViewController {

    private var viewModel = DI.resolve(ServiceStatusViewModel.self)!
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.portalMaintenanceStatus.subscribe {[weak self] status in
            switch status {
            case is MaintenanceStatus.AllPortal:
                self?.showPortalMaintenance()
            case is MaintenanceStatus.Product:
                self?.showLanding()
            default:
                break
            }
        } onError: { [weak self] error in
            self?.handleErrors(error)
        }.disposed(by: disposeBag)
    }
    
    private func showPortalMaintenance() {
        //TODO: Maintenance
    }
    
    private func showLanding() {
        NavigationManagement.sharedInstance.goTo(storyboard: "Lanunch", viewControllerId: "LaunchViewController")
    }

}
