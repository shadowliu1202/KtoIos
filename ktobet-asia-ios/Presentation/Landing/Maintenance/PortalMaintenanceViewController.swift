import RxSwift
import sharedbu
import SnapKit
import SwiftUI
import UIKit

class PortalMaintenanceViewController: LandingViewController {
    @AppStorage(UserDefaults.Key.cultureCode.rawValue) var cultureCode: String?

    private lazy var hostingController: UIHostingController<AnyView> = {
        let currentLocale = if let cultureCode {
            Configuration.forceChinese ? SupportLocale.China() : SupportLocale.companion.create(language: cultureCode)
        } else {
            SupportLocale.Vietnam()
        }

        let fontName = KTOFontWeight.regular.fontString(currentLocale)

        let portalMaintenanceView = PortalMaintenanceView(dismissHandler: { [weak self] in
            self?.navigateToLogin()
        })
        .environment(\.locale, .init(identifier: currentLocale.cultureCode()))
        .environment(\.font, .custom(fontName, size: 16))
        .foregroundStyle(.textPrimary)
        .onHandleError { [unowned self] error in
            self.handleErrors(error)
        }

        return UIHostingController(rootView: AnyView(portalMaintenanceView))
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        hostingController.didMove(toParent: self)
    }

    private func navigateToLogin() {
        NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
    }
}
