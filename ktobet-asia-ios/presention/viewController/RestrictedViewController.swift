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
        
        viewModel.output.portalMaintenanceStatus.drive {[weak self] status in
            switch status {
            case is MaintenanceStatus.AllPortal:
                self?.showPortalMaintenance()
            case is MaintenanceStatus.Product:
                self?.showLanding()
            default:
                break
            }
        }.disposed(by: disposeBag)
    }
    
    private func showPortalMaintenance() {
        NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
    }
    
    private func showLanding() {
        NavigationManagement.sharedInstance.goTo(storyboard: "Lanunch", viewControllerId: "LaunchViewController")
    }

}
