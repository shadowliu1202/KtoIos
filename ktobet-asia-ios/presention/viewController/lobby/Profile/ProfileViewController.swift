import RxCocoa
import RxSwift
import SharedBu
import UIKit

class ProfileViewController: LobbyViewController, AuthProfileVerification {
  let httpClient = Injectable.resolve(HttpClient.self)!
  @IBOutlet weak var passwordView: OneItemView!
  @IBOutlet weak var gameIdLabel: UILabel!
  @IBOutlet weak var tipsIcon: UIButton!
  @IBOutlet weak var emailView: TwoItemView!
  @IBOutlet weak var mobileView: TwoItemView!
  @IBOutlet weak var realNameView: TwoItemView!
  @IBOutlet weak var birthdayView: TwoItemView!
  @IBOutlet weak var settingView: OneItemView!
  @IBOutlet weak var aboutView: OneItemView!
  @IBOutlet weak var affiliateView: OneItemView!
  @IBOutlet weak var affiliateViewHeight: NSLayoutConstraint!

  private var viewModel = Injectable.resolve(ModifyProfileViewModel.self)!
  private var portalServiceViewModel = Injectable.resolve(ServiceStatusViewModel.self)!
  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: Localize.string("profile_my"))
    dataBinding()
    setChangePasswordAction()
    setUpTips()
    setUpSetting()
    setUpTerms()
  }

  private func dataBinding() {
    self.rx.viewWillAppear.flatMap({ [unowned self] _ in
      self.viewModel.fetchPlayerProfile()
    }).subscribe(onError: { [weak self] in
      self?.handleErrors($0)
    }).disposed(by: disposeBag)

    self.rx.viewWillAppear.flatMap({ [unowned self] _ in
      self.viewModel.profileAuthorization
    }).subscribe(onNext: { [weak self] in
      if $0 == .unauthenticated {
        self?.navigateToAuthorization()
      }
    }).disposed(by: disposeBag)

    self.rx.viewWillAppear.flatMap({ [unowned self] _ in
      self.viewModel.playerProfile
    }).subscribe(onNext: { [weak self] in
      self?.setUpUI($0)
    }).disposed(by: disposeBag)

    Observable.combineLatest(self.viewModel.playerProfile, self.viewModel.isAnyWithdrawalTicketApplying.asObservable())
      .subscribe(onNext: { [weak self] profile, applyIsOnGoing in
        self?.setRealName(profile.realName, isOnGoing: applyIsOnGoing)
      }).disposed(by: disposeBag)

    checkAffiliate()
  }

  private func setUpUI(_ profile: PlayerProfile) {
    setGameId(profile.gameId)
    setEmail(profile.email)
    setMobile(profile.mobile)
    setBirthday(profile.birthDay)
  }

  private func setChangePasswordAction() {
    passwordView.setOnClick { [weak self] in
      self?.performSegue(withIdentifier: ChangePasswordViewController.segueIdentifier, sender: nil)
    }
  }

  private func setGameId(_ gameId: String) {
    gameIdLabel.text = gameId
  }

  private func setEmail(_ email: EditableContent<String?>) {
    emailView.setUp(email) { [weak self] in
      guard let self else { return }
      self.portalServiceViewModel.output.otpService.subscribe { status in
        if email.editable {
          self.setUpEmailModifyAction(email.content, status.isMailActive)
        }
      } onFailure: { [weak self] error in
        self?.handleErrors(error)
      }.disposed(by: self.disposeBag)
    }
  }

  private func setUpEmailModifyAction(_ content: String?, _ isMailActive: Bool) {
    let emailType = EmailAccountType()
    if isMailActive {
      startIdentityModification(content, emailType)
    }
    else {
      alertOtpServiceInactive(emailType)
    }
  }

  private func startIdentityModification(_ origin: String?, _ accountType: AccountTypeProtocol) {
    if origin.isNullOrEmpty() {
      navigateToSetNewIdentity(accountType)
    }
    else {
      confirmOldAccountModification(origin!, accountType)
    }
  }

  private func navigateToSetNewIdentity(_ accountType: AccountTypeProtocol) {
    accountType.navigateToSetNewIdentity()
  }

  private func confirmOldAccountModification(_ origin: String, _ accountType: AccountTypeProtocol) {
    Alert.shared.show(Localize.string("common_tip_title_warm"), accountType.identityAreadyHint, confirm: {
      accountType.navigateToConfirmPage(origin)
    }, cancel: { [weak self] in self?.dismiss(animated: true, completion: nil) })
  }

  private func alertOtpServiceInactive(_ accountType: AccountTypeProtocol) {
    Alert.shared.show(accountType.otpUnavailableTitle, accountType.otpUnavailableDescription, confirm: { [weak self] in
      self?.dismiss(animated: true, completion: nil)
    }, confirmText: Localize.string("common_determine"), cancel: nil)
  }

  private func setMobile(_ mobile: EditableContent<String?>) {
    mobileView.setUp(mobile) { [weak self] in
      guard let self else { return }
      self.portalServiceViewModel.output.otpService.subscribe { status in
        if mobile.editable {
          self.setUpMobileModifyAction(mobile.content, status.isSmsActive)
        }
      } onFailure: { [weak self] error in
        self?.handleErrors(error)
      }.disposed(by: self.disposeBag)
    }
  }

  private func setUpMobileModifyAction(_ content: String?, _ isSmsActive: Bool) {
    let mobileType = MobileAccounType()
    if isSmsActive {
      startIdentityModification(content, mobileType)
    }
    else {
      alertOtpServiceInactive(mobileType)
    }
  }

  private func setRealName(_ name: EditableContent<String?>, isOnGoing: Bool) {
    realNameView.setUp(name) { [weak self] in
      if isOnGoing {
        self?.alertWithdrawalOnGoing()
      }
      else {
        self?.performSegue(withIdentifier: SetWithdrawalNameViewController.segueIdentifier, sender: nil)
      }
    }
  }

  private func setBirthday(_ birthday: EditableContent<String?>) {
    birthdayView.setUp(birthday) { [weak self] in
      self?.performSegue(withIdentifier: SetBirthdayViewController.segueIdentifier, sender: nil)
    }
  }

  private func setUpTips() {
    tipsIcon.rx.touchUpInside.bind(onNext: {
      Alert.shared.show(
        Localize.string("profile_player_game_id"),
        Localize.string("profile_player_game_id_description"),
        confirm: nil,
        cancel: nil)
    }).disposed(by: disposeBag)
  }

  private func setUpSetting() {
    settingView.setOnClick {
      self.performSegue(withIdentifier: SettingsViewController.segueIdentifier, sender: nil)
    }
  }

  private func setUpTerms() {
    aboutView.setOnClick({ [weak self] in
      self?.performSegue(withIdentifier: TermsViewController.segueIdentifier, sender: nil)
    })
  }

  private func checkAffiliate() {
    viewModel.isAffiliateMember
      .subscribe(onSuccess: { [weak self] in
        guard let self else { return }
        self.affiliateView.isHidden = !$0
        self.affiliateViewHeight.constant = $0 ? 48 : 0
        self.affiliateView.setOnClick {
          self.pressAffiliate()
        }
      }).disposed(by: disposeBag)
  }

  private func pressAffiliate() {
    viewModel.getAffiliateHashKey()
      .map { [unowned self] in
        self.viewModel.getAffiliateUrl(host: httpClient.host, hashKey: $0)
      }
      .subscribe(onSuccess: {
        guard let url = $0 else { return }
        let vc = AffiliateViewController(url: url)
        vc.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        self.present(vc, animated: true)
      })
      .disposed(by: disposeBag)
  }

  private func alertWithdrawalOnGoing() {
    Alert.shared.show(
      Localize.string("common_tip_title_warm"),
      Localize.string("profile_real_name_ticket_on_going_not_editable"),
      confirm: { },
      cancel: nil)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

protocol AccountTypeProtocol {
  var type: AccountType { get set }
  var otpUnavailableTitle: String { get set }
  var otpUnavailableDescription: String { get set }
  var identityAreadyHint: String { get set }

  func navigateToConfirmPage(_ origin: String)
  func navigateToSetNewIdentity()
}

struct EmailAccountType: AccountTypeProtocol {
  var type: AccountType = .email
  var otpUnavailableTitle = Localize.string("profile_mail_unavailable_title")
  var otpUnavailableDescription = Localize.string("profile_mail_unavailable_description")
  var identityAreadyHint = Localize.string("profile_identity_email_bound_already_hint")

  func navigateToConfirmPage(_ identity: String) {
    let oldAccountModifyConfirmationViewController = UIStoryboard(name: "Profile", bundle: nil)
      .instantiateViewController(
        withIdentifier: "OldAccountModifyConfirmationViewController") as! OldAccountModifyConfirmationViewController
    oldAccountModifyConfirmationViewController.delegate = OldEmailModifyConfirmViewController(email: identity)
    NavigationManagement.sharedInstance.pushViewController(vc: oldAccountModifyConfirmationViewController)
  }

  func navigateToSetNewIdentity() {
    let setIdentityViewController = UIStoryboard(name: "Profile", bundle: nil)
      .instantiateViewController(withIdentifier: "SetIdentityViewController") as! SetIdentityViewController
    setIdentityViewController.delegate = SetEmailIdentity(mode: .new)
    NavigationManagement.sharedInstance.pushViewController(vc: setIdentityViewController)
  }
}

struct MobileAccounType: AccountTypeProtocol {
  var type: AccountType = .phone
  var otpUnavailableTitle = Localize.string("profile_sms_unavailable_title")
  var otpUnavailableDescription = Localize.string("profile_sms_unavailable_description")
  var identityAreadyHint = Localize.string("profile_identity_mobile_bound_already_hint")

  func navigateToConfirmPage(_ identity: String) {
    let oldAccountModifyConfirmationViewController = UIStoryboard(name: "Profile", bundle: nil)
      .instantiateViewController(
        withIdentifier: "OldAccountModifyConfirmationViewController") as! OldAccountModifyConfirmationViewController
    oldAccountModifyConfirmationViewController.delegate = OldMobileModifyConfirmViewController(mobile: identity)
    NavigationManagement.sharedInstance.pushViewController(vc: oldAccountModifyConfirmationViewController)
  }

  func navigateToSetNewIdentity() {
    let setIdentityViewController = UIStoryboard(name: "Profile", bundle: nil)
      .instantiateViewController(withIdentifier: "SetIdentityViewController") as! SetIdentityViewController
    setIdentityViewController.delegate = SetMobileIdentity(mode: .new)
    NavigationManagement.sharedInstance.pushViewController(vc: setIdentityViewController)
  }
}

class OneItemView: UIView {
  private var clickCallback: (() -> Void)?
  override init(frame: CGRect) {
    super.init(frame: frame)
    addGesture()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    addGesture()
  }

  func setOnClick(_ callback: @escaping () -> Void) {
    self.clickCallback = callback
  }

  private func addGesture() {
    let gesture = UITapGestureRecognizer(target: self, action: #selector(self.touchAction(_:)))
    self.isUserInteractionEnabled = true
    self.addGestureRecognizer(gesture)
  }

  @objc
  private func touchAction(_: UITapGestureRecognizer) {
    self.clickCallback?()
  }
}

class TwoItemView: UIView {
  @IBOutlet weak var valueLabel: UILabel!
  @IBOutlet weak var icon: UIImageView!
  private var gesture: UITapGestureRecognizer?
  private var clickCallback: (() -> Void)? {
    didSet {
      if let _ = clickCallback {
        addGesture()
      }
      else {
        removeGesture()
      }
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  func setUp(_ data: EditableContent<String?>, _ callback: (() -> Void)?) {
    if let content = data.content, !content.isEmpty {
      self.valueLabel.text = content
      self.valueLabel.textColor = .gray9B9B9B
    }
    else {
      self.valueLabel.text = Localize.string("profile_field_not_set")
      self.valueLabel.textColor = .yellowFFD500
    }
    self.icon.isHidden = !data.editable
    if data.editable {
      self.clickCallback = callback
    }
    else {
      self.clickCallback = nil
    }
  }

  func setOnClick(_ callback: @escaping () -> Void) {
    self.clickCallback = callback
  }

  private func addGesture() {
    guard gesture == nil else { return }
    gesture = UITapGestureRecognizer(target: self, action: #selector(self.touchAction(_:)))
    self.isUserInteractionEnabled = true
    self.addGestureRecognizer(gesture!)
  }

  @objc
  private func touchAction(_: UITapGestureRecognizer) {
    self.clickCallback?()
  }

  private func removeGesture() {
    if let gesture {
      self.removeGestureRecognizer(gesture)
      self.gesture = nil
    }
  }
}
