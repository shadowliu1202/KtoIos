import RxSwift
import sharedbu
import SwiftUI
import UIKit

class LoginViewController: LandingViewController {
  @IBOutlet weak var logoItem: UIBarButtonItem!

  @Injected private var viewModel: LoginViewModel
  @Injected private var customerServiceViewModel: CustomerServiceViewModel
  @Injected private var systemStatusUseCase: ISystemStatusUseCase
  @Injected private var serviceStatusViewModel: ServiceStatusViewModel
  @Injected private var cookieManager: CookieManager
  @Injected private var alert: AlertProtocol
  
  private let segueSignup = "GoToSignup"

  private let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
  private let register = UIBarButtonItem.kto(.register)
  private let spacing = UIBarButtonItem.kto(.text(text: "|")).isEnable(false)
  private let update = UIBarButtonItem.kto(.manulUpdate).isEnable(true)
  private lazy var customService = UIBarButtonItem
    .kto(.cs(
      supportLocale: viewModel.getSupportLocale(),
      customerServiceViewModel: customerServiceViewModel,
      serviceStatusViewModel: serviceStatusViewModel,
      alert: alert,
      delegate: self,
      disposeBag: disposeBag))
  
  private let disposeBag = DisposeBag()
  private var viewDisappearBag = DisposeBag()
  
  lazy var barButtonItems = [padding, register, spacing, customService]
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    cookieManager.replaceCulture(to: viewModel.getCultureCode())
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    Logger.shared.info("\(type(of: self)) viewDidLoad.")
    logoItem.image = UIImage(named: "KTO (D)")?.withRenderingMode(.alwaysOriginal)
    if Configuration.manualUpdate {
      let spacing2 = UIBarButtonItem.kto(.text(text: "|")).isEnable(false)
      barButtonItems.append(contentsOf: [spacing2, update])
    }
    self.bind(position: .right, barButtonItems: barButtonItems)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    observeSystemStatus()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    viewDisappearBag = DisposeBag()
  }

  private func observeSystemStatus() {
    systemStatusUseCase
      .fetchMaintenanceStatus()
      .subscribe(
        onSuccess: { status in
          switch status {
          case is MaintenanceStatus.AllPortal:
            NavigationManagement.sharedInstance.goTo(
              storyboard: "Maintenance",
              viewControllerId: "PortalMaintenanceViewController")
          default:
            break
          }
        },
        onFailure: { [weak self] error in
          guard let self else { return }

          self.handleErrors(error)
        })
      .disposed(by: disposeBag)
  }

  private func localize() {
    register.title = Localize.string("common_register")
    customService.title = Localize.string("customerservice_action_bar_title")
    update.title = Localize.string("update_title")
  }

  @IBSegueAction
  func segueToHostingController(_ coder: NSCoder) -> UIViewController? {
    UIHostingController(
      coder: coder,
      rootView: LoginView(
        viewModel: viewModel,
        onLogin: { [unowned self] pageNavigation, error in
          if let pageNavigation {
            executeNavigation(pageNavigation)
          }

          if let error {
            switch error {
            case is InvalidPlatformException:
              showServiceDownAlert()
            default:
              handleErrors(error)
            }
          }
        },
        onResetPassword: { [unowned self] in navigateToResetPasswordPage() }))
  }

  private func executeNavigation(_ navigation: NavigationViewModel.LobbyPageNavigation) {
    switch navigation {
    case .portalAllMaintenance:
      navigateToPortalMaintenancePage()
    case .playerDefaultProduct(let product):
      navigateToProductPage(product)
    case .setDefaultProduct:
      navigateToSetDefaultProductPage()
    }
  }

  private func navigateToPortalMaintenancePage() {
    alert.show(
      Localize.string("common_maintenance_notify"),
      Localize.string("common_maintenance_contact_later"),
      confirm: {
        NavigationManagement.sharedInstance.goTo(
          storyboard: "Maintenance",
          viewControllerId: "PortalMaintenanceViewController")
      },
      cancel: nil)
  }

  private func navigateToProductPage(_ productType: ProductType) {
    NavigationManagement.sharedInstance.goTo(productType: productType)
  }

  private func navigateToSetDefaultProductPage() {
    NavigationManagement.sharedInstance.goToSetDefaultProduct()
  }
  
  private func showServiceDownAlert() {
    alert.show(
      Localize.string("common_tip_cn_down_title_warm"),
      Localize.string("common_cn_service_down"),
      confirm: nil,
      confirmText: Localize.string("common_cn_down_confirm"))
  }
  
  private func navigateToResetPasswordPage() {
    serviceStatusViewModel.output.otpService
      .subscribe(
        onSuccess: { [unowned self] otpStatus in
          if otpStatus.isSmsActive || otpStatus.isMailActive {
            performSegue(withIdentifier: ResetPasswordViewController.segueIdentifier, sender: nil)
          }
          else {
            alert.show(
              Localize.string("common_error"),
              Localize.string("login_resetpassword_service_down"))
          }
        },
        onFailure: { [unowned self] in handleErrors($0) })
      .disposed(by: self.disposeBag)
  }

  @IBAction
  func backToLogin(segue: UIStoryboardSegue) {
    segue.source.presentationController?.delegate?.presentationControllerDidDismiss?(segue.source.presentationController!)
    if let vc = segue.source as? ResetPasswordStep3ViewController {
      if vc.changePasswordSuccess {
        showToast(Localize.string("login_resetpassword_success"), barImg: .success)
      }
    }
  }
}

extension LoginViewController {
  override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
    if
      let navi = segue.destination as? UINavigationController,
      let signupVc = navi.viewControllers.first as? SignupLanguageViewController
    {
      signupVc.languageChangeHandler = { currentLocale in
        self.changeCSButton(currentLocale)
        self.localize()
      }
      signupVc.presentationController?.delegate = self
    }
    if
      let navi = segue.destination as? UINavigationController,
      let vc = navi.viewControllers.first as? ResetPasswordViewController
    {
      vc.presentationController?.delegate = self
    }
  }
  
  private func changeCSButton(_ currentLocale: SupportLocale) {
    customService = UIBarButtonItem
      .kto(.cs(
        supportLocale: currentLocale,
        customerServiceViewModel: customerServiceViewModel,
        serviceStatusViewModel: serviceStatusViewModel,
        alert: alert,
        delegate: self,
        disposeBag: disposeBag))
    
    let index = barButtonItems.firstIndex(where: { $0 is CustomerServiceButtonItem })!
    barButtonItems[index] = customService
    
    if
      var rightBarButtonItems = navigationItem.rightBarButtonItems,
      let currentCSIndex = rightBarButtonItems.firstIndex(where: { $0 is CustomerServiceButtonItem })
    {
      rightBarButtonItems[currentCSIndex] = customService
      bind(position: .right, barButtonItems: rightBarButtonItems)
    }
  }

  override func unwind(for _: UIStoryboardSegue, towards _: UIViewController) { }
}

extension LoginViewController: BarButtonItemable {
  func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
    switch sender.tag {
    case registerBarBtnId:
      let language = Language(rawValue: viewModel.getCultureCode())
      if language == .CN {
        alertServiceDownThenToSignUpPage()
      }
      else {
        navigateToSignUpPage()
      }
    case manualUpdateBtnId:
      Configuration.isAutoUpdate = true
      appSyncViewModel.getLatestAppVersion().subscribe(onSuccess: { [weak self] inComingAppVersion in
        self?.versionAlert(inComingAppVersion)
      }, onFailure: { [weak self] in
        self?.handleErrors($0)
      }).disposed(by: disposeBag)
    default:
      break
    }
  }
  
  private func alertServiceDownThenToSignUpPage() {
    let attributedText = AttributedText(text: Localize.string("common_cn_service_down"))
      .font(UIFont(name: "PingFangSC-Regular", size: 14)!)
    
    alert.show(
      Localize.string("common_tip_cn_down_title_warm"),
      attributedText,
      confirm: { [weak self] in
        self?.navigateToSignUpPage()
      },
      confirmText: Localize.string("common_cn_down_confirm"))
  }
  
  private func navigateToSignUpPage() {
    serviceStatusViewModel.output.otpService
      .subscribe(
        onSuccess: { [unowned self] otpStatus in
          if
            !otpStatus.isMailActive,
            !otpStatus.isSmsActive
          {
            alert.show(Localize.string("common_error"), Localize.string("register_service_down"))
          }
          else {
            performSegue(withIdentifier: segueSignup, sender: nil)
          }
        },
        onFailure: { [unowned self] in handleErrors($0) })
      .disposed(by: disposeBag)
  }

  private func versionAlert(_ newVer: Version) {
    let currentVersion = Bundle.main.currentVersion
    let currentVersionCode = currentVersion.versionCode
    let newVersionCode = newVer.versionCode
    let title = Localize.string("update_proceed_now")
    let msg = "目前版本 : \(currentVersion)+\(currentVersionCode) \n最新版本 : \(newVer)+\(newVersionCode)"
    if currentVersion.compareTo(other: newVer) < 0 {
      alert.show(title, msg, confirm: { [weak self] in
        guard let self else { return }
        self.syncAppVersionUpdate(self.viewDisappearBag)
      }, confirmText: Localize.string("update_proceed_now"), cancel: { }, cancelText: "稍後")
    }
    else {
      alert.show(title, msg, confirm: { }, confirmText: "無需更新", cancel: nil)
    }
  }
}

extension LoginViewController: CustomServiceDelegate {
  func customServiceBarButtons() -> [UIBarButtonItem]? {
    [spacing, customService]
  }
}
