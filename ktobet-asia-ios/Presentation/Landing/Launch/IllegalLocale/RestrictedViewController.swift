import RxSwift
import sharedbu
import UIKit

class RestrictedViewController: UIViewController {
    private var viewModel = Injectable.resolve(ServiceStatusViewModel.self)!
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification).take(until: self.rx.deallocated)
            .subscribe(onNext: { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.output.portalMaintenanceStatus.subscribe(onNext: { [weak self] status in
            switch onEnum(of: status) {
            case .allPortal:
                self?.showPortalMaintenance()
            case .product:
                self?.showLanding()
            }
        }).disposed(by: disposeBag)
    }

    private func showPortalMaintenance() {
        NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
    }

    private func showLanding() {
        NavigationManagement.sharedInstance.goTo(storyboard: "Launch", viewControllerId: "LaunchViewController")
    }
}
