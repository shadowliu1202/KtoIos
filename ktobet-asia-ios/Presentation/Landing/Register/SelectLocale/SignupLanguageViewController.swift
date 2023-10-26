import RxCocoa
import RxSwift
import sharedbu
import UIKit

class SignupLanguageViewController: LandingViewController {
  var barButtonItems: [UIBarButtonItem] = []

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

  @Injected private var cookieManager: CookieManager
  
  private let localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!
  private let serviceStatusViewModel = Injectable.resolve(ServiceStatusViewModel.self)!
  
  private let segueLogin = "BackToLogin"
  private let segueInfo = "GoToInfo"
  private let segueTerms = "GoToTermsOfService"
  private let rowHeight: CGFloat = 72
  private let rowSpace: CGFloat = 12

  private var disposeBag = DisposeBag()
  private var arrLangs: [SupportLocale] = [SupportLocale.Vietnam()]

  private var padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
  private lazy var login = UIBarButtonItem.kto(.login)
  private var spacing = UIBarButtonItem.kto(.text(text: "|")).isEnable(false)
  private lazy var customService = UIBarButtonItem
    .kto(.cs(serviceStatusViewModel: serviceStatusViewModel, delegate: self, disposeBag: disposeBag))

  var languageChangeHandler: ((_ currentLocale: SupportLocale) -> Void)?

  // MARK: Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    self.bind(position: .right, barButtonItems: padding, login, spacing, customService)
    setTableViewHeight()
    setupStyle()
    if let locale = arrLangs.first {
      onLocaleChange(locale: locale)
    }
  }

  // MARK: METHOD
  private func refreshLocalize() {
    login.title = Localize.string("common_login")
    customService.title = Localize.string("customerservice_action_bar_title")
    labTitle.text = Localize.string("register_step1_title_1")
    labDesc.text = Localize.string("register_step1_title_2")
    labTermsTip.text = Localize.string("register_step1_tips_1")
    btnNext.setTitle(Localize.string("common_next"), for: .normal)
    btnTerms.setTitle(Localize.string("register_step1_tips_1_highlight"), for: .normal)
  }

  private func setTableViewHeight() {
    constraintTableHeight.constant = {
      var height = rowHeight * CGFloat(arrLangs.count)
      if height > 12 { height -= 12 }
      return height
    }()
  }

  private func registerOptionText(_ local: SupportLocale) -> String {
    switch local {
    case is SupportLocale.Vietnam:
      return Localize.string("register_language_option_vietnam")
    case is SupportLocale.China:
      fallthrough
    default:
      return Localize.string("register_language_option_chinese")
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
    performSegue(withIdentifier: segueLogin, sender: nil)
  }

  func btnLoginPressed() {
    performSegue(withIdentifier: segueLogin, sender: nil)
  }

  @IBAction
  func btnTipPressed(_: UIButton) {
    let title = Localize.string("common_tip_title_warm")
    let message = Localize.string("common_tip_content_bind")
    Alert.shared.show(title, message, confirm: nil, cancel: nil)
  }

  private func onLocaleChange(locale: SupportLocale) {
    localStorageRepo.setCultureCode(locale.cultureCode())
    Theme.shared.changeEntireAPPFont(by: locale)
    cookieManager.replaceCulture(to: locale.cultureCode())
    changeViewFont(by: locale)
    (customService as! CustomerServiceButtonItem).changeLocale(locale)
    refreshLocalize()
    languageChangeHandler?(locale)
    Injectable.resetObjectScope(.locale)
    CustomServicePresenter.shared.changeCsDomainIfNeed()
    tableView.reloadData()
  }

  private func changeViewFont(by playerLocale: SupportLocale) {
    let fontDictionary: [String: UIFont]
    fontDictionary = Theme.shared.getSignupLanguageViewFont(by: playerLocale)
    btnNext.titleLabel?.font = fontDictionary["btnNext"]
    btnTerms.titleLabel?.font = fontDictionary["btnTerms"]
    labTitle.font = fontDictionary["labTitle"]
    labDesc.font = fontDictionary["labDesc"]
    labTermsTip.font = fontDictionary["labTermsTip"]
    btnTermsOfService.titleLabel?.font = fontDictionary["btnTermsOfService"]
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

  override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
    if
      let vc = segue.destination as? SignupUserinfoViewController
    {
      vc.locale = localStorageRepo.getSupportLocale()
    }
  }
}

extension SignupLanguageViewController: BarButtonItemable {
  func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
    switch sender.tag {
    case loginBarBtnId:
      btnLoginPressed()
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
