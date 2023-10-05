import RxSwift
import SharedBu
import SwiftUI
import UIKit

class LoginViewController: LandingViewController {
  @IBOutlet weak var logoItem: UIBarButtonItem!

  @Injected var viewModel: LoginViewModel

  private let segueSignup = "GoToSignup"

  private let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
  private let register = UIBarButtonItem.kto(.register)
  private let spacing = UIBarButtonItem.kto(.text(text: "|")).isEnable(false)
  private let update = UIBarButtonItem.kto(.manulUpdate).isEnable(true)

  private let cookieHandler = CookieHandler()
  
  private let disposeBag = DisposeBag()
  private var viewDisappearBag = DisposeBag()

  private lazy var customService = UIBarButtonItem
    .kto(.cs(serviceStatusViewModel: serviceStatusViewModel, delegate: self, disposeBag: disposeBag))
  private lazy var serviceStatusViewModel = Injectable.resolveWrapper(ServiceStatusViewModel.self)
  private lazy var getSystemStatusUseCase = Injectable.resolveWrapper(ISystemStatusUseCase.self)
  
  var barButtonItems: [UIBarButtonItem] = []
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    cookieHandler.replaceCulture(to: viewModel.getCultureCode())
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    Logger.shared.info("\(type(of: self)) viewDidLoad.")
    logoItem.image = UIImage(named: "KTO (D)")?.withRenderingMode(.alwaysOriginal)
    var barButtoms = [padding, register, spacing, customService]
    if Configuration.manualUpdate {
      let spacing2 = UIBarButtonItem.kto(.text(text: "|")).isEnable(false)
      barButtoms.append(contentsOf: [spacing2, update])
    }
    self.bind(position: .right, barButtonItems: barButtoms)
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
    getSystemStatusUseCase
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
        onLogin: { [weak self] pageNavigation, generalError in
          if let pageNavigation {
            self?.executeNavigation(pageNavigation)
          }

          if let generalError {
            self?.handleErrors(generalError)
          }
        }, onResetPassword: { [weak self] in
          self?.navigateToResetPasswordPage()
        }))
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
    NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
  }

  private func navigateToProductPage(_ productType: ProductType) {
    NavigationManagement.sharedInstance.goTo(productType: productType)
  }

  private func navigateToMaintainPage(_ type: ProductType) {
    NavigationManagement.sharedInstance.goTo(productType: type, isMaintenance: true)
  }

  private func alertMaintenance(product: ProductType, onConfirm: @escaping (() -> Void)) {
    Alert.shared.show(
      Localize.string("common_maintenance_notify"),
      Localize.string(
        "common_default_product_maintain_content",
        StringMapper.parseProductTypeString(productType: product)),
      confirm: onConfirm,
      cancel: nil)
  }

  private func navigateToSetDefaultProductPage() {
    NavigationManagement.sharedInstance.goToSetDefaultProduct()
  }

  private func navigateToSignUpPage() {
    serviceStatusViewModel.output.otpService.subscribe { [weak self] otpStatus in
      if !otpStatus.isMailActive, !otpStatus.isSmsActive {
        let title = Localize.string("common_error")
        let message = Localize.string("register_service_down")
        Alert.shared.show(title, message, confirm: nil, cancel: nil)
      }
      else {
        self?.performSegue(withIdentifier: self!.segueSignup, sender: nil)
      }
    } onFailure: { [weak self] error in
      self?.handleErrors(error)
    }.disposed(by: disposeBag)
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

  private func navigateToResetPasswordPage() {
    self.serviceStatusViewModel.output.otpService.subscribe(onSuccess: { [weak self] otpStatus in
      if otpStatus.isSmsActive || otpStatus.isMailActive {
        self?.performSegue(withIdentifier: ResetPasswordViewController.segueIdentifier, sender: nil)
      }
      else {
        Alert.shared.show(
          Localize.string("common_error"),
          Localize.string("login_resetpassword_service_down"),
          confirm: { },
          cancel: nil)
      }
    }, onFailure: { [weak self] error in
      self?.handleErrors(error)
    }).disposed(by: self.disposeBag)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

extension LoginViewController {
  override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
    if
      let navi = segue.destination as? UINavigationController,
      let signupVc = navi.viewControllers.first as? SignupLanguageViewController
    {
      signupVc.languageChangeHandler = {
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

  override func unwind(for _: UIStoryboardSegue, towards _: UIViewController) { }
}

extension LoginViewController: BarButtonItemable {
  func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
    switch sender.tag {
    case registerBarBtnId:
      let language = Language(rawValue: viewModel.getCultureCode())
      if language == .CN {
        showServiceDownAlert()
      }
      else {
        btnSignupPressed()
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

  private func btnSignupPressed() {
    serviceStatusViewModel.output.otpService.subscribe { [weak self] otpStatus in
      if !otpStatus.isMailActive, !otpStatus.isSmsActive {
        let title = Localize.string("common_error")
        let message = Localize.string("register_service_down")
        Alert.shared.show(title, message, confirm: nil, cancel: nil)
      }
      else {
        self?.performSegue(withIdentifier: self!.segueSignup, sender: nil)
      }
    } onFailure: { [weak self] error in
      self?.handleErrors(error)
    }.disposed(by: disposeBag)
  }

  private func versionAlert(_ newVer: Version) {
    let currentVersion = Bundle.main.currentVersion
    let currentVersionCode = currentVersion.versionCode
    let newVersionCode = newVer.versionCode
    let title = Localize.string("update_proceed_now")
    let msg = "目前版本 : \(currentVersion)+\(currentVersionCode) \n最新版本 : \(newVer)+\(newVersionCode)"
    if currentVersion.compareTo(other: newVer) < 0 {
      Alert.shared.show(title, msg, confirm: { [weak self] in
        guard let self else { return }
        self.syncAppVersionUpdate(self.viewDisappearBag)
      }, confirmText: Localize.string("update_proceed_now"), cancel: { }, cancelText: "稍後")
    }
    else {
      Alert.shared.show(title, msg, confirm: { }, confirmText: "無需更新", cancel: nil)
    }
  }
  
  private func showServiceDownAlert() {
    Alert.shared
      .show(
        Localize.string("common_tip_title_warm"),
        Localize.string("common_cn_service_down"),
        confirm: { [weak self] in
          self?.btnSignupPressed()
        },
        confirmText: Localize.string("common_confirm"))
  }
}

extension LoginViewController: CustomServiceDelegate {
  func customServiceBarButtons() -> [UIBarButtonItem]? {
    [spacing, customService]
  }
}
