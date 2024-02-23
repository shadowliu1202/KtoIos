import RxCocoa
import RxSwift
import sharedbu
import SideMenu
import UIKit

class SideBarViewController: APPViewController {
  @IBOutlet private weak var btnGift: UIBarButtonItem!
  @IBOutlet private weak var btnNotification: UIBarButtonItem!
  @IBOutlet private weak var btnClose: UIBarButtonItem!
  @IBOutlet private weak var listProduct: UICollectionView!
  @IBOutlet private weak var listFeature: UITableView!
  @IBOutlet private weak var constraintListProductHeight: NSLayoutConstraint!
  @IBOutlet private weak var constraintListFeatureHeight: NSLayoutConstraint!
  @IBOutlet private weak var labBalance: UILabel!
  @IBOutlet private weak var btnBalanceRefresh: UIButton!
  @IBOutlet private weak var btnBalanceHide: UIButton!
  @IBOutlet private weak var labUserLevel: UILabel!
  @IBOutlet private weak var labUserAcoount: UILabel!
  @IBOutlet private weak var labUserName: UILabel!
  @IBOutlet private weak var accountView: UIView!
  @IBOutlet private weak var levelView: UIView!
  @IBOutlet private weak var balanceView: UIView!
  
  private let products = {
    let titles = [
      Localize.string("common_sportsbook"),
      Localize.string("common_casino"),
      Localize.string("common_slot"),
      Localize.string("common_keno"),
      Localize.string("common_p2p"),
      Localize.string("common_arcade")
    ]

    let imgs = ["SBK", "Casino", "Slot", "Number Game", "P2P", "Arcade"]
    let types: [ProductType] = [.sbk, .casino, .slot, .numberGame, .p2P, .arcade]

    return Swift.zip(titles, Swift.zip(imgs, types))
      .map { title, imgAndType in
        let (image, type) = imgAndType
        return ProductItem(title: title, image: image, type: type)
      }
  }()
  
  private let features = [
    FeatureItem(type: .deposit, name: Localize.string("common_deposit"), icon: "Deposit"),
    FeatureItem(type: .withdraw, name: Localize.string("common_withdrawal"), icon: "Withdrawl"),
    FeatureItem(type: .callService, name: Localize.string("common_customerservice"), icon: "Customer Service"),
    FeatureItem(type: .logout, name: Localize.string("common_logout"), icon: "Logout")
  ]
  
  private let balanceHiddenStateSubject = BehaviorRelay(value: true)
  private let productSelectedSubject = BehaviorRelay<ProductType?>(value: nil)

  private var disposeBag = DisposeBag()

  private var gamerID = ""
  private var isAlertShowing = false

  var sideMenuViewModel: SideMenuViewModel? = SideMenuViewModel()
  var maintenanceViewModel: MaintenanceViewModel? = Injectable.resolveWrapper(MaintenanceViewModel.self)
  var customerServiceViewModel: CustomerServiceViewModel? = Injectable.resolveWrapper(CustomerServiceViewModel.self)

  override func viewDidLoad() {
    super.viewDidLoad()
    initUI()
    dataBinding()
    selectEventBinding()
    
    setupNetworkRetry()

    guard
      let menu = navigationController as? SideMenuNavigationController,
      menu.blurEffectStyle == nil
    else { return }

    menu.sideMenuDelegate = self

    let appearance = UINavigationBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.shadowColor = .clear
    appearance.shadowImage = .init()
    appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.greyScaleWhite]
    appearance.backgroundColor = UIColor.greyScaleSidebar.withAlphaComponent(0.9)
    navigationController?.navigationBar.scrollEdgeAppearance = appearance
    navigationController?.navigationBar.standardAppearance = appearance
  }
  
  override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change: [NSKeyValueChangeKey: Any]?,
    context _: UnsafeMutableRawPointer?)
  {
    if keyPath == "contentSize", let newvalue = change?[.newKey] {
      if let obj = object as? UICollectionView, obj == listProduct {
        constraintListProductHeight.constant = (newvalue as! CGSize).height
      }
      if let obj = object as? UITableView, obj == listFeature {
        constraintListFeatureHeight.constant = (newvalue as! CGSize).height
      }
    }
  }

  func observeSystemStatus() {
    observeKickOutSignal()
    observeMaintenanceStatus()
  }
  
  private func observeKickOutSignal() {
    guard let sideMenuViewModel else { return }
    
    sideMenuViewModel.observeKickOutSignal()
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [unowned self] in alertAndExitLobby($0) })
      .disposed(by: disposeBag)
  }
  
  private func observeMaintenanceStatus() {
    guard let maintenanceViewModel else { return }
    
    maintenanceViewModel.portalMaintenanceStatus
      .drive(onNext: { [unowned self] _ in alertAndExitLobby(KickOutSignal.Maintenance) })
      .disposed(by: disposeBag)
  }

  private func alertAndExitLobby(_ type: KickOutSignal?, cancel: (() -> Void)? = nil) {
    guard !isAlertShowing else { return }
    isAlertShowing = true
    
    Task { @MainActor in
      let (title, message, isMaintain) = await parseKickOutType(type)
      
      Alert.shared.show(title, message, confirm: { [weak self] in
        guard
          let self,
          let maintenanceStatusViewModel = self.maintenanceViewModel
        else { return }
        
        maintenanceStatusViewModel.logout()
          .subscribe(
            onCompleted: {
              if isMaintain {
                NavigationManagement.sharedInstance.goTo(
                  storyboard: "Maintenance",
                  viewControllerId: "PortalMaintenanceViewController")
              }
              else {
                NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
              }
            },
            onError: { _ in self.isAlertShowing = false })
          .disposed(by: self.disposeBag)
        
      }, cancel: cancel)
    }
  }

  private func parseKickOutType(_ type: KickOutSignal?) async -> (String, String, Bool) {
    var title = Localize.string("common_tip_title_warm")
    var message = Localize.string("common_confirm_logout")
    var isMaintain = false

    switch type {
    case .duplicatedLogin:
      title = Localize.string("common_tip_title_warm")
      message = Localize.string("common_notify_logout_content")
      isMaintain = false

    case .Suspend:
      title = Localize.string("common_tip_title_warm")
      message = Localize.string("common_kick_out_suspend")
      isMaintain = false

    case .Inactive:
      title = Localize.string("common_tip_title_warm")
      message = Localize.string("common_kick_out_inactive")
      isMaintain = false

    case .Maintenance:
      if
        let customerServiceViewModel,
        let isPlayerInChat = try? await customerServiceViewModel.isPlayerInChat.first().value,
        isPlayerInChat
      {
        title = Localize.string("common_maintenance_notify")
        message = Localize.string("common_maintenance_chat_close")
        isMaintain = true
      }
      else {
        title = Localize.string("common_urgent_maintenance")
        message = Localize.string("common_maintenance_logout")
        isMaintain = true
      }

    case .TokenExpired:
      title = Localize.string("common_kick_out_token_expired_title")
      message = Localize.string("common_kick_out_token_expired")
      isMaintain = false

    case .none:
      break
    }

    return (title, message, isMaintain)
  }

  override func handleErrors(_ error: Error) {
    guard !error.isNetworkLost() else { return }
    
    if error.isUnauthorized() {
      logoutToLanding()
    }
    else {
      super.handleErrors(error)
    }
  }
  
  private func logoutToLanding() {
    Task { @MainActor in
      try? await maintenanceViewModel?.logout().value
      NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
    }
  }

  override func networkDisconnectHandler() {
    // Do Nothing.
  }

  private func setupNetworkRetry() {
    networkConnectRelay
      .skip(1)
      .subscribe(onNext: { [weak sideMenuViewModel] isConnected in
        if isConnected {
          sideMenuViewModel?.refreshData()
        }
      })
      .disposed(by: disposeBag)
  }
  
  func deallocate() {
    sideMenuViewModel = nil
    maintenanceViewModel = nil
    disposeBag = DisposeBag()
  }

  // MARK: - UI
  private func initUI() {
    guard let sideMenuViewModel else { return }
    
    let navigationBar = navigationController?.navigationBar
    navigationBar?.barTintColor = UIColor.greyScaleSidebar
    navigationBar?.isTranslucent = false
    navigationBar?.setBackgroundImage(UIImage(), for: .default)
    navigationBar?.shadowImage = UIImage()
    labUserAcoount.numberOfLines = 0
    labUserAcoount.lineBreakMode = .byWordWrapping
    let logoImageView = UIImageView(image: UIImage(named: "KTO (D)"))
    logoImageView.contentMode = .scaleAspectFit
    
    #if DEBUG
      logoImageView.isUserInteractionEnabled = true
      logoImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(logoItemOnTap)))
    #endif
    
    let logoView = UIView()
    logoView.addSubview(logoImageView)
    logoImageView.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(15)
      make.top.bottom.trailing.equalToSuperview()
    }
    let logoItem = UIBarButtonItem(customView: logoView)
    navigationItem.leftBarButtonItem = logoItem
    btnNotification.image = UIImage(named: "Notification-None")?.withRenderingMode(.alwaysOriginal)
    listFeature.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    listProduct.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    listProduct.collectionViewLayout = {
      let space = CGFloat(10)
      let width = (UIScreen.main.bounds.size.width - space * 5) / 4
      let flowLayout = UICollectionViewFlowLayout()
      flowLayout.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
      if sideMenuViewModel.getSupportLoacle() == SupportLocale.China() {
        flowLayout.itemSize = CGSize(width: width, height: 84)
      }
      else {
        flowLayout.itemSize = CGSize(width: width, height: 124)
      }
      flowLayout.minimumLineSpacing = 12
      flowLayout.minimumInteritemSpacing = space
      return flowLayout
    }()

    labBalance.lineBreakMode = .byCharWrapping
    labUserAcoount.numberOfLines = 0
    labUserAcoount.lineBreakMode = .byCharWrapping
    
    let labAccountTap = UITapGestureRecognizer(target: self, action: #selector(self.accountTap(_:)))
    self.accountView.isUserInteractionEnabled = true
    self.accountView.addGestureRecognizer(labAccountTap)

    let labAccountLevelTap = UITapGestureRecognizer(target: self, action: #selector(self.accountLevelTap(_:)))
    self.levelView.isUserInteractionEnabled = true
    self.levelView.addGestureRecognizer(labAccountLevelTap)

    let labBalanceTap = UITapGestureRecognizer(target: self, action: #selector(self.balanceTap(_:)))
    self.balanceView.isUserInteractionEnabled = true
    self.balanceView.addGestureRecognizer(labBalanceTap)
  }

  // MARK: - Binding

  private func dataBinding() {
    guard
      let sideMenuViewModel,
      let maintenanceViewModel
    else { return }
    
    playerInfoBinding(sideMenuViewModel)
    balanceBinding(sideMenuViewModel)
    productsListBinding(maintenanceViewModel)
    featuresBinding()
    errorsHandingBinding()
  }
  
  private func playerInfoBinding(_ sideMenuViewModel: SideMenuViewModel) {
    sideMenuViewModel.playerInfo
      .drive(onNext: { [unowned self] in updatePlayerInfoUI($0) })
      .disposed(by: disposeBag)
    
    sideMenuViewModel.playerInfo.asObservable()
      .first()
      .compactMap { $0 }
      .subscribe(onSuccess: { [unowned self] in
        // FIXME: Avoid using `sideMenuViewModel` here, as the strong reference created by this statement leads to a
        // problem where the viewController isn't released. Even manually setting `sideMenuViewModel` to nil doesn't release it
        // because the strong reference in the closure keeps it alive. The current implementation avoids this strong reference
        // issue.
        guard let viewModel = self.sideMenuViewModel else { return }

        productSelectedSubject.accept($0.defaultProduct)
        balanceHiddenStateSubject.accept(viewModel.loadBalanceHiddenState(by: $0.gamerID))
      })
      .disposed(by: disposeBag)
  }
  
  private func updatePlayerInfoUI(_ playerInfo: PlayerInfoDTO) {
    gamerID = playerInfo.gamerID
    
    labUserLevel.text = Localize.string("common_level_2", "\(playerInfo.level)")
    labUserAcoount.text = "\(AccountMask.maskAccount(account: playerInfo.displayID))"
    labUserName.text = "\(playerInfo.gamerID)"
  }

  private func balanceBinding(_ sideMenuViewModel: SideMenuViewModel) {
    Driver.combineLatest(
      sideMenuViewModel.playerBalance
        .map { "\($0.symbol) \($0.formatString())" },
      balanceHiddenStateSubject.asDriverOnErrorJustComplete()) { ($0, $1) }
      .drive(onNext: { [unowned self] balanceString, isHidden in
        if isHidden {
          btnBalanceHide.setTitle(Localize.string("common_show"), for: .normal)
          labBalance.text = "\(balanceString.first ?? " ") •••••••"
        }
        else {
          btnBalanceHide.setTitle(Localize.string("common_hide"), for: .normal)
          labBalance.text = balanceString
        }
      })
      .disposed(by: disposeBag)
  }
  
  private func productsListBinding(_ maintenanceViewModel: MaintenanceViewModel) {
    let productsStatus = maintenanceViewModel.productMaintenanceStatus
      .map { [products] status in
        products
          .map { $0.updateMaintainTime(status.getMaintenanceTime(productType: $0.type)) }
      }
      .startWith(products)
      
    Driver.combineLatest(
      productsStatus,
      productSelectedSubject.asDriver()) { productItems, _ in productItems }
      .drive(listProduct.rx.items) { [unowned self] collection, row, data in
        updateProductListCell(view: collection, at: row, source: data)
      }
      .disposed(by: disposeBag)
  }
  
  private func updateProductListCell(view: UICollectionView, at row: Int, source data: ProductItem) -> ProductItemCell {
    guard let cell = view.dequeueReusableCell(withReuseIdentifier: "ProductItemCell", for: [0, row]) as? ProductItemCell
    else { return .init() }

    cell.setup(data)
    cell.finishCountDown = { [weak self] in
      Task { await self?.maintenanceViewModel?.pullMaintenanceStatus() }
    }

    cell.setSelectedIcon(isSelected: data.type == productSelectedSubject.value)

    return cell
  }
  
  private func featuresBinding() {
    Observable.of(features)
      .bind(to: listFeature.rx.items(
        cellIdentifier: String(describing: FeatureItemCell.self),
        cellType: FeatureItemCell.self))
    { _, data, cell in
      cell.setup(data.name, image: UIImage(named: data.icon))
    }
    .disposed(by: disposeBag)
  }

  func cleanProductSelected() {
    productSelectedSubject.accept(nil)
  }
  
  private func errorsHandingBinding() {
    sideMenuViewModel?.errors()
      .observe(on: MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] error in
        self?.handleErrors(error)
      })
      .disposed(by: disposeBag)
    
    maintenanceViewModel?.errors()
      .observe(on: MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak self] error in
        self?.handleErrors(error)
      })
      .disposed(by: disposeBag)
  }

  // MARK: - Select Event

  private func selectEventBinding() {
    productSelectBinding()
    featureSelectBinding()
  }

  private func productSelectBinding() {
    listProduct.rx.modelSelected(ProductItem.self)
      .subscribe(onNext: { [productSelectedSubject] in
        NavigationManagement.sharedInstance
          .goTo(productType: $0.type, isMaintenance: $0.maintainTime != nil)
      
        productSelectedSubject.accept($0.type)
      })
      .disposed(by: disposeBag)
  }

  private func featureSelectBinding() {
    Observable.zip(
      listFeature.rx.itemSelected,
      listFeature.rx.modelSelected(FeatureItem.self))
      .bind { [unowned self] indexPath, data in
        let featureType = data.type
      
        if featureType != .logout {
          cleanProductSelected()
        }

        switch featureType {
        case .logout:
          alertAndExitLobby(nil, cancel: { [weak self] in self?.isAlertShowing = false })
        case .withdraw:
          NavigationManagement.sharedInstance.goTo(storyboard: "Withdrawal", viewControllerId: "WithdrawalNavigation")
        case .deposit:
          NavigationManagement.sharedInstance.goTo(storyboard: "Deposit", viewControllerId: "DepositNavigation")
        case .callService:
          navigationController?.pushViewController(CustomerServiceMainViewController(), animated: false)
        }

        listFeature.deselectRow(at: indexPath, animated: true)
      }
      .disposed(by: disposeBag)
  }

  // MARK: - Touch Event
  @IBAction
  func btnClosePressed(_: UIButton) {
    navigationController?.dismiss(animated: true, completion: nil)
  }

  @IBAction
  func btnHideBalance(_: UIButton) {
    toggleBalanceHiddenState()
  }
  
  private func toggleBalanceHiddenState() {
    let currentHiddenState = balanceHiddenStateSubject.value
    balanceHiddenStateSubject.accept(!currentHiddenState)
    sideMenuViewModel?.saveBalanceHiddenState(gamerID: gamerID, isHidden: !currentHiddenState)
  }

  @IBAction
  func btnRefreshBalance(_: UIButton) {
    sideMenuViewModel?.refreshPlayerBalance()
  }

  @objc
  func accountTap(_: UITapGestureRecognizer) {
    let rootVC = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.rootViewController
    NavigationManagement.sharedInstance.previousRootViewController = rootVC
    NavigationManagement.sharedInstance.navigateToAuthorization()
  }

  @objc
  func accountLevelTap(_: UITapGestureRecognizer) {
    cleanProductSelected()
    NavigationManagement.sharedInstance.goTo(
      storyboard: "LevelPrivilege",
      viewControllerId: "LevelPrivilegeNavigationController")
  }

  @objc
  func balanceTap(_: UITapGestureRecognizer) {
    cleanProductSelected()
    NavigationManagement.sharedInstance.goTo(storyboard: "TransactionLog", viewControllerId: "TransactionLogNavigation")
  }

  @IBAction
  func toGift(_: UIButton) {
    cleanProductSelected()
    NavigationManagement.sharedInstance.goTo(storyboard: "Promotion", viewControllerId: "PromotionNavigationController")
  }

  @IBAction
  func toNotify(_: UIButton) {
    cleanProductSelected()
    NavigationManagement.sharedInstance.goTo(
      storyboard: "Notification",
      viewControllerId: "AccountNotificationNavigationController")
  }

  @IBAction
  func logoItemOnTap() {
    Configuration.forceChinese.toggle()
    Localize = LocalizeUtils(supportLocale: Configuration.forceChinese ? SupportLocale.China() : SupportLocale.Vietnam())
    let sideBarVC = SideBarViewController.initFrom(storyboard: "slideMenu")
    navigationController?.viewControllers = [sideBarVC]
  }
}

// MARK: - SideMenuNavigationControllerDelegate

extension SideBarViewController: SideMenuNavigationControllerDelegate {
  func sideMenuWillAppear(menu _: SideMenuNavigationController, animated _: Bool) {
    sideMenuViewModel?.refreshData()
    Task { await maintenanceViewModel?.pullMaintenanceStatus() }
    
    CustomServicePresenter.shared.setFloatIconAvailable(false)
  }

  func sideMenuWillDisappear(menu _: SideMenuNavigationController, animated _: Bool) {
    CustomServicePresenter.shared.setFloatIconAvailable(true)
  }
}
