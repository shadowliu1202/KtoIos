import Foundation
import RxSwift
import sharedbu
import UIKit

class CommonFailViewController: CommonViewController {
    static let segueIdentifier = "GoToFail"
  
    @IBOutlet private weak var naviItem: UINavigationItem!
    @IBOutlet private weak var imgFailIcon: UIImageView!
    @IBOutlet private weak var labTitle: UILabel!
    @IBOutlet private weak var labDesc: UILabel!
    @IBOutlet private weak var btnRestart: UIButton!
    @IBOutlet private weak var scollView: UIScrollView!

    @Injected private var customerServiceViewModel: CustomerServiceViewModel
    @Injected private var serviceStatusViewModel: ServiceStatusViewModel
    @Injected private var playerConfiguration: PlayerConfiguration
    @Injected private var alert: AlertProtocol
  
    private let disposeBag = DisposeBag()

    private var padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    private lazy var customService = UIBarButtonItem
        .kto(.cs(
            supportLocale: playerConfiguration.supportLocale,
            customerServiceViewModel: customerServiceViewModel,
            serviceStatusViewModel: serviceStatusViewModel,
            alert: alert,
            delegate: self,
            disposeBag: disposeBag))

    var barButtonItems: [UIBarButtonItem] = []
    var commonFailedType: CommonFailedTypeProtocol!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.bind(position: .right, barButtonItems: commonFailedType.barItems)
        localize()
        defaultStyle()
    }

    // MARK: METHOD
    private func localize() {
        labTitle.text = commonFailedType.title
        labDesc.text = commonFailedType.description
        btnRestart.setTitle(commonFailedType.buttonTitle, for: .normal)
    }

    private func defaultStyle() {
        naviItem.titleView = UIImageView(image: Configuration.current.navigationIcon())
        btnRestart.layer.cornerRadius = 9
        btnRestart.layer.masksToBounds = true
        scollView.backgroundColor = UIColor.greyScaleDefault
    }

    @IBAction
    private func btnRestartPressed(_: UIButton) {
        commonFailedType.back?()
    }
}

protocol CommonFailedTypeProtocol {
    var title: String { get set }
    var description: String { get set }
    var buttonTitle: String { get set }
    var barItems: [UIBarButtonItem] { get set }
    var back: (() -> Void)? { get set }
}

struct CommonFailedType: CommonFailedTypeProtocol {
    var title = ""
    var description = ""
    var buttonTitle = ""
    var barItems: [UIBarButtonItem] = []
    var back: (() -> Void)?
}

struct ResetPasswrodFailedType: CommonFailedTypeProtocol {
    var title: String = Localize.string("login_resetpassword_fail_title")
    var description = ""
    var buttonTitle: String = Localize.string("common_back")
    var barItems: [UIBarButtonItem] = []
    var back: (() -> Void)? = { UIApplication.topViewController()?.navigationController?.dismiss(animated: true, completion: nil)
    }
}

struct RegisterFailedType: CommonFailedTypeProtocol {
    var title: String = Localize.string("register_step4_title_fail")
    var description: String = Localize.string("register_step4_content_fail")
    var buttonTitle: String = Localize.string("register_step4_retry_signup")
    var barItems: [UIBarButtonItem] = []
    var back: (() -> Void)? = { UIApplication.topViewController()?.navigationController?.popToRootViewController(animated: true) }
}

struct ProfileEmailFailedType: CommonFailedTypeProtocol {
    var title: String = Localize.string("profile_email_inactive")
    var description = ""
    var buttonTitle: String = Localize.string("common_back")
    var barItems: [UIBarButtonItem] = []
    var back: (() -> Void)? = { NavigationManagement.sharedInstance.popToRootViewController() }
}

struct ProfileMobileFailedType: CommonFailedTypeProtocol {
    var title: String = Localize.string("profile_sms_inactive")
    var description = ""
    var buttonTitle: String = Localize.string("common_back")
    var barItems: [UIBarButtonItem] = []
    var back: (() -> Void)? = { NavigationManagement.sharedInstance.popToRootViewController() }
}

struct WithdrawalFailedType: CommonFailedTypeProtocol {
    var title: String = Localize.string("cps_secruity_verification_failure")
    var description: String = Localize.string("profile_sms_inactive")
    var buttonTitle: String = Localize.string("common_back")
    var barItems: [UIBarButtonItem] = []
    var back: (() -> Void)? = { NavigationManagement.sharedInstance.popToRootViewController() }
}

extension CommonFailViewController: BarButtonItemable { }

extension CommonFailViewController: CustomServiceDelegate {
    func customServiceBarButtons() -> [UIBarButtonItem]? {
        [padding, customService]
    }
}
