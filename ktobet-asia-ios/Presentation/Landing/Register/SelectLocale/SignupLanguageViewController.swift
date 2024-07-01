import RxCocoa
import RxSwift
import sharedbu
import UIKit

class SignupLanguageViewController: LandingViewController {
    struct LanguageListData {
        var title: String
        var type: SupportLocale
        var selected: Bool
    }

    @IBOutlet private weak var naviItem: UINavigationItem!
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var btnNext: UIButton!
    @IBOutlet private weak var btnTerms: UIButton!
    @IBOutlet private weak var labTitle: UILabel!
    @IBOutlet private weak var labDesc: UILabel!
    @IBOutlet private weak var labTermsTip: UILabel!
    @IBOutlet private weak var btnTermsOfService: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var constraintTableHeight: NSLayoutConstraint!

    @Injected private var customerServiceViewModel: CustomerServiceViewModel
    @Injected private var serviceStatusViewModel: ServiceStatusViewModel
    @Injected private var localStorageRepo: LocalStorageRepository
    @Injected private var playerConfiguration: PlayerConfiguration
    @Injected private var cookieManager: CookieManager
    @Injected private var alert: AlertProtocol
  
    private let segueLogin = "BackToLogin"
    private let segueInfo = "GoToInfo"
    private let segueTerms = "GoToTermsOfService"
    private let rowHeight: CGFloat = 72
    private let rowSpace: CGFloat = 12

    private var disposeBag = DisposeBag()
    private var arrLangs: [SupportLocale] = {
        #if QAT
            return [SupportLocale.China(), SupportLocale.Vietnam()]
        #else
            return [SupportLocale.Vietnam()]
        #endif
    }()

    private var padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    private lazy var login = UIBarButtonItem.kto(.login)
    private var spacing = UIBarButtonItem.kto(.text(text: "|")).isEnable(false)
    private lazy var customService = UIBarButtonItem
        .kto(.cs(
            supportLocale: playerConfiguration.supportLocale,
            customerServiceViewModel: customerServiceViewModel,
            serviceStatusViewModel: serviceStatusViewModel,
            alert: alert,
            delegate: self,
            disposeBag: disposeBag))

    var languageChangeHandler: (() -> Void)?
    lazy var barButtonItems: [UIBarButtonItem] = [padding, login, spacing, customService]

    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.bind(position: .right, barButtonItems: barButtonItems)
        setTableViewHeight()
        setupStyle()
    }

    private func setTableViewHeight() {
        constraintTableHeight.constant = {
            var height = rowHeight * CGFloat(arrLangs.count)
            if height > 12 { height -= 12 }
            return height
        }()
    }

    private func registerOptionText(_ locale: SupportLocale) -> String {
        switch onEnum(of: locale) {
        case .china:
            return Localize.string("register_language_option_chinese")
        case .vietnam:
            return Localize.string("register_language_option_vietnam")
        }
    }

    private func setupStyle() {
        naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
        btnNext.layer.cornerRadius = 9
        btnNext.layer.masksToBounds = true
    }

    // MARK: BUTTON ACTION
    @IBAction
    func btnTermsOfServicePressed(_: UIButton) {
        let controller = TermsOfServiceViewController.instantiate(ServiceTerms(barItemType: .close))
        navigationController?.pushViewController(controller, animated: true)
    }

    @IBAction
    func btnNextPressed(_: UIButton) {
        performSegue(withIdentifier: segueInfo, sender: nil)
    }

    @IBAction
    func btnBackPressed(_: UIButton) {
        dismiss(animated: true)
    }

    @IBAction
    func btnTipPressed(_: UIButton) {
        let title = Localize.string("common_tip_title_warm")
        let message = Localize.string("common_tip_content_bind")
        Alert.shared.show(title, message, confirm: nil, cancel: nil)
    }

    private func onLocaleChange(locale: SupportLocale) {
        handlePlayerSessionChange(locale: locale)
        languageChangeHandler?()
        recreateVC()
    }
  
    private func recreateVC() {
        let signupLanguageVC = SignupLanguageViewController.initFrom(storyboard: "Signup")
        signupLanguageVC.languageChangeHandler = languageChangeHandler
        navigationController?.viewControllers = [signupLanguageVC]
    }
}

extension SignupLanguageViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: TABLE VIEW
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        arrLangs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: LanguageAndCurrencyCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! LanguageAndCurrencyCell
        let locale = arrLangs[indexPath.row]
        let data = LanguageListData(
            title: registerOptionText(locale),
            type: locale,
            selected: locale.cultureCode() == localStorageRepo.getCultureCode())
        cell.setup(data)
        cell.didSelectOn = { [weak self] _ in
            self?.onLocaleChange(locale: locale)
        }
        return cell
    }
  
    func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.onLocaleChange(locale: arrLangs[indexPath.row])
    }

    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        rowHeight
    }
}

extension SignupLanguageViewController {
    // MARK: PAGE ACTION
    @IBAction
    func backToLanguageList(segue _: UIStoryboardSegue) { }
    override func unwind(for _: UIStoryboardSegue, towards _: UIViewController) { }
}

extension SignupLanguageViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        switch sender.tag {
        case loginBarBtnId:
            dismiss(animated: true)
        default:
            break
        }
    }
}

extension SignupLanguageViewController: CustomServiceDelegate {
    func customServiceBarButtons() -> [UIBarButtonItem]? {
        [spacing, customService]
    }
}
