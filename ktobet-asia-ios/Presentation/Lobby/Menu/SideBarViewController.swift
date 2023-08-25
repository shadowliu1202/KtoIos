import RxCocoa
import RxSwift
import SharedBu
import SideMenu
import UIKit

class SideBarViewController: APPViewController {
  @IBOutlet private weak var btnGift: UIBarButtonItem!
  @IBOutlet private weak var btnNotification: UIBarButtonItem!
  @IBOutlet private weak var btnClose: UIBarButtonItem!
  @IBOutlet private weak var naviItem: UIBarButtonItem!
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
  private var firstTimeEntry = true

  var sideMenuViewModel: SideMenuViewModel? = SideMenuViewModel()

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

  func observeKickOutSignal() {
    guard let sideMenuViewModel else { return }
    
    sideMenuViewModel.observeKickOutSignal()
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [unowned self] in alertAndExitLobby($0) })
      .disposed(by: disposeBag)
  }

  private func alertAndExitLobby(_ type: KickOutSignal?, cancel: (() -> Void)? = nil) {
    let (title, message, isMaintain) = parseKickOutType(type)

    Alert.shared.show(title, message, confirm: { [weak self] in
      guard
        let self,
        let sideMenuViewModel = self.sideMenuViewModel
      else { return }

      sideMenuViewModel.logout()
        .subscribe(onCompleted: {
          if isMaintain {
            NavigationManagement.sharedInstance.goTo(
              storyboard: "Maintenance",
              viewControllerId: "PortalMaintenanceViewController")
          }
          else {
            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
          }
        })
        .disposed(by: self.disposeBag)

    }, cancel: cancel)
  }

  private func parseKickOutType(_ type: KickOutSignal?) -> (String, String, Bool) {
    var title: String
    var message: String
    var isMaintain: Bool

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
      if CustomServicePresenter.shared.isInChat {
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

    default:
      title = Localize.string("common_tip_title_warm")
      message = Localize.string("common_confirm_logout")
      isMaintain = false
    }

    return (title, message, isMaintain)
  }

  override func handleErrors(_ error: Error) {
    if !error.isNetworkLost() {
      super.handleErrors(error)
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
    naviItem.image = UIImage(named: "KTO (D)")?.withRenderingMode(.alwaysOriginal)
    btnNotification.image = UIImage(named: "Notification-None")?.withRenderingMode(.alwaysOriginal)
    listFeature.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    listProduct.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    listProduct.collectionViewLayout = {
      let space = CGFloat(10)
      let width = (UIScreen.main.bounds.size.width - space * 5) / 4
      let flowLayout = UICollectionViewFlowLayout()
      flowLayout.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
      if sideMenuViewModel.getCultureCode() == SupportLocale.China().cultureCode() {
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
    guard let sideMenuViewModel else { return }
    
    playerInfoBinding(sideMenuViewModel)
    balanceBinding(sideMenuViewModel)
    productsListBinding(sideMenuViewModel)
    featuresBinding()
    maintenanceStatusBinding(sideMenuViewModel)
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
  
  private func productsListBinding(_ sideMenuViewModel: SideMenuViewModel) {
    Driver.combineLatest(
      sideMenuViewModel.productsStatus,
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
      self?.sideMenuViewModel?.refreshMaintenanceStatus()
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

  private func maintenanceStatusBinding(_ sideMenuViewModel: SideMenuViewModel) {
    sideMenuViewModel.maintenanceStatus
      .filter { $0 is MaintenanceStatus.AllPortal }
      .drive(onNext: { [unowned self] _ in alertAndExitLobby(KickOutSignal.Maintenance) })
      .disposed(by: disposeBag)
  }

  func cleanProductSelected() {
    productSelectedSubject.accept(nil)
  }
  
  private func errorsHandingBinding() {
    sideMenuViewModel?.errors()
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
          alertAndExitLobby(nil, cancel: { })
        case .withdraw:
          NavigationManagement.sharedInstance.goTo(storyboard: "Withdrawal", viewControllerId: "WithdrawalNavigation")
        case .deposit:
          NavigationManagement.sharedInstance.goTo(storyboard: "Deposit", viewControllerId: "DepositNavigation")
        case .callService:
          NavigationManagement.sharedInstance.goTo(
            storyboard: "CustomService",
            viewControllerId: "CustomerServiceMainNavigationController")
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
  func manualUpdate() {
    if Configuration.manualUpdate {
      Configuration.isAutoUpdate = true
    }
  }
}

// MARK: - SideMenuNavigationControllerDelegate

extension SideBarViewController: SideMenuNavigationControllerDelegate {
  func sideMenuWillAppear(menu _: SideMenuNavigationController, animated _: Bool) {
    if !firstTimeEntry {
      sideMenuViewModel?.refreshData()
    }
    
    CustomServicePresenter.shared.isInSideMenu = true
    firstTimeEntry = false
  }

  func sideMenuWillDisappear(menu _: SideMenuNavigationController, animated _: Bool) {
    CustomServicePresenter.shared.isInSideMenu = false
  }
}
