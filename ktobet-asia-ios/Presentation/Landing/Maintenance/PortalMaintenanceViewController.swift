import RxSwift
import sharedbu
import SnapKit
import SwiftUI
import UIKit

class PortalMaintenanceViewController: LandingViewController {
    private var hostingController: UIHostingController<PortalMaintenanceView>?

    override func viewDidLoad() {
        super.viewDidLoad()

        let portalMaintenanceView = PortalMaintenanceView(dismissHandler: { [weak self] in
            self?.navigateToLogin()
        })
        hostingController = UIHostingController(rootView: portalMaintenanceView)

        if let hostingController = hostingController {
            addChild(hostingController)
            view.addSubview(hostingController.view)

            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            hostingController.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            hostingController.didMove(toParent: self)
        }
    }

    private func navigateToLogin() {
        NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
    }
}
