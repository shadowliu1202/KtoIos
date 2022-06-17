import Foundation
import UIKit
import RxSwift
import SharedBu

class CommonFailViewController: CommonViewController {
    static let segueIdentifier = "GoToFail"
    var barButtonItems: [UIBarButtonItem] = []

    @IBOutlet private weak var naviItem: UINavigationItem!
    @IBOutlet private weak var imgFailIcon: UIImageView!
    @IBOutlet private weak var labTitle: UILabel!
    @IBOutlet private weak var labDesc: UILabel!
    @IBOutlet private weak var btnRestart: UIButton!
    @IBOutlet private weak var scollView: UIScrollView!

    private var padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    private lazy var customService = UIBarButtonItem.kto(.cs(delegate: self, disposeBag: disposeBag))

    var commonFailedType: CommonFailedTypeProtocol!
    private var disposeBag = DisposeBag()
    
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
        naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
        btnRestart.layer.cornerRadius = 9
        btnRestart.layer.masksToBounds = true
        scollView.backgroundColor = UIColor.black_two
    }

    @IBAction private func btnRestartPressed(_ sender: UIButton) {
        commonFailedType.back?()
    }
}

protocol CommonFailedTypeProtocol {
    var title: String { get set }
    var description: String { get set }
    var buttonTitle: String { get set }
    var barItems: [UIBarButtonItem] { get set }
    var back: (() -> ())? { get set }
}

struct CommonFailedType: CommonFailedTypeProtocol {
    var title: String = ""
    var description: String = ""
    var buttonTitle: String = ""
    var barItems: [UIBarButtonItem] = []
    var back: (() -> ())? = nil
}

struct ResetPasswrodFailedType: CommonFailedTypeProtocol {
    var title: String = Localize.string("login_resetpassword_fail_title")
    var description: String = ""
    var buttonTitle: String = Localize.string("common_back")
    var barItems: [UIBarButtonItem] = []
    var back: (() -> ())? = { UIApplication.topViewController()?.navigationController?.dismiss(animated: true, completion: nil) }
}

struct RegisterFailedType: CommonFailedTypeProtocol {
    var title: String = Localize.string("register_step4_title_fail")
    var description: String = Localize.string("register_step4_content_fail")
    var buttonTitle: String = Localize.string("register_step4_retry_signup")
    var barItems: [UIBarButtonItem] = []
    var back: (() -> ())? = { UIApplication.topViewController()?.navigationController?.popToRootViewController(animated: true) }
}

struct ProfileEmailFailedType: CommonFailedTypeProtocol {
    var title: String = Localize.string("profile_email_inactive")
    var description: String = ""
    var buttonTitle: String = Localize.string("common_back")
    var barItems: [UIBarButtonItem] = []
    var back: (() -> ())? = { NavigationManagement.sharedInstance.popToRootViewController() }
}

struct ProfileMobileFailedType: CommonFailedTypeProtocol {
    var title: String = Localize.string("profile_sms_inactive")
    var description: String = ""
    var buttonTitle: String = Localize.string("common_back")
    var barItems: [UIBarButtonItem] = []
    var back: (() -> ())? = { NavigationManagement.sharedInstance.popToRootViewController() }
}

struct WithdrawalFailedType: CommonFailedTypeProtocol {
    var title: String = Localize.string("cps_secruity_verification_failure")
    var description: String = Localize.string("profile_sms_inactive")
    var buttonTitle: String = Localize.string("common_back")
    var barItems: [UIBarButtonItem] = []
    var back: (() -> ())? = { NavigationManagement.sharedInstance.popToRootViewController() }
}

extension CommonFailViewController: BarButtonItemable { }

extension CommonFailViewController: CustomServiceDelegate {
    func customServiceBarButtons() -> [UIBarButtonItem]? {
        [padding, customService]
    }
}
