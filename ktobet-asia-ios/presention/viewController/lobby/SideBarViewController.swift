import UIKit
import RxSwift
import RxCocoa
import SharedBu
import SideMenu

class SideBarViewController: LobbyViewController {
    
    @IBOutlet private weak var btnGift: UIBarButtonItem!
    @IBOutlet private weak var btnNotification: UIBarButtonItem!
    @IBOutlet private weak var btnClose: UIBarButtonItem!
    @IBOutlet private weak var naviItem : UIBarButtonItem!
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
    
    private let localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!
    private let playerViewModel = Injectable.resolve(PlayerViewModel.self)!
    private let serviceViewModel = Injectable.resolve(ServiceStatusViewModel.self)!
    
    private let refreshTrigger = PublishSubject<Void>()
    private let balanceTrigger = PublishSubject<Void>()
    private let disposeBag = DisposeBag()
    
    private var productMaintenanceStatus: MaintenanceStatus.Product?
    private var balanceSummary = ""
    private var gameId = ""
    private var isBalanceLabelHidden = false

    var sideMenuViewModel: SideMenuViewModel? = Injectable.resolveWrapper(SideMenuViewModel.self)
  
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        initFeatures()
        eventHandler()
        dataBinding()
        setupNetworkRetry()
        
        guard let menu = navigationController as? SideMenuNavigationController, menu.blurEffectStyle == nil else {
            return
        }
        
        menu.sideMenuDelegate = self
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.whitePure]
        appearance.backgroundColor = UIColor.gray202020.withAlphaComponent(0.9)
        self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        self.navigationController?.navigationBar.standardAppearance = appearance
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize", let newvalue = change?[.newKey] {
            if let obj = object as? UICollectionView , obj == listProduct{
                constraintListProductHeight.constant = (newvalue as! CGSize).height
            }
            if let obj = object as? UITableView, obj == listFeature{
                constraintListFeatureHeight.constant = (newvalue as! CGSize).height
            }
        }
    }
  
    func observeLoginStatus() {
        sideMenuViewModel!
          .observeLoginStatus()
          .subscribe(onNext: { [weak self] loginStatusDTO in
            guard let self else { return }
            
            switch loginStatusDTO {
            case .kickout(let type):
              self.alertAndExitLobby(type)
            case .fetch:
              break
            }
          })
          .disposed(by: disposeBag)
    }
    
    private func alertAndExitLobby(_ type: KickOutSignal?, cancel: (() -> ())? = nil) {
          let (title, message, isMaintain) = parseKickOutType(type)
          
          Alert.shared.show(title, message, confirm: { [weak self] in
              guard let self = self else { return }
              
              self.playerViewModel.logout()
                  .subscribe(on: MainScheduler.instance)
                  .subscribe(onCompleted: {
                      if isMaintain {
                          NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
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
            if CustomServicePresenter.shared.topViewController is ChatRoomViewController {
                title = Localize.string("common_maintenance_notify")
                message = Localize.string("common_maintenance_contact_later")
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
    
    private func dataRefresh() {
        refreshTrigger.onNext(())
        sideMenuViewModel!.fetchData()
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
            .subscribe(onNext: { [weak self] isConnected in
                if isConnected {
                    self?.dataRefresh()
                }
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UI

extension SideBarViewController {
    
    private func initUI() {
        let navigationBar = navigationController?.navigationBar
        navigationBar?.barTintColor = UIColor.gray202020
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
            if localStorageRepo.getCultureCode() == SupportLocale.China.init().cultureCode() {
                flowLayout.itemSize = CGSize(width: width, height: 84)
            } else {
                flowLayout.itemSize = CGSize(width: width, height: 124)
            }
            flowLayout.minimumLineSpacing = 12
            flowLayout.minimumInteritemSpacing = space
            return flowLayout
        }()
        
        labBalance.lineBreakMode = .byCharWrapping
        labUserAcoount.numberOfLines = 0
        labUserAcoount.lineBreakMode = .byCharWrapping
    }
    
    private func initFeatures() {
      sideMenuViewModel!.features.bind(to: listFeature.rx.items(cellIdentifier: String(describing: FeatureItemCell.self), cellType: FeatureItemCell.self)) { index, data, cell in
            cell.setup(data.name, image: UIImage(named: data.icon))
        }.disposed(by: disposeBag)
    }
    
    func cleanProductSelected() {
        self.sideMenuViewModel!.currentSelectedProductType = ProductType.none
        self.listProduct.reloadData()
    }
    
    private func updatePlayerInfoUI(_ player: Player) {
        self.labUserLevel.text = Localize.string("common_level_2", "\(player.playerInfo.level)")
        self.labUserAcoount.text = "\(AccountMask.maskAccount(account: player.playerInfo.displayId))"
        self.labUserName.text = "\(player.playerInfo.gameId)"
    }
    
    private func updateProductListCell(view: UICollectionView, at row: Int, source data: ProductItem) -> ProductItemCell {
        guard  let cell = view.dequeueReusableCell(withReuseIdentifier: "ProductItemCell", for: [0, row]) as? ProductItemCell
        else { return .init() }
                
        cell.setup(data)
        cell.finishCountDown = { [weak self] in
            self?.sideMenuViewModel!.fetchMaintenanceStatus()
        }
        
        if let selectedProductType = self.sideMenuViewModel!.currentSelectedProductType, data.type == selectedProductType {
            cell.setSelectedIcon(selectedProductType, isSelected: true)
            self.listProduct.selectItem(at: IndexPath(item: row, section: 0), animated: true, scrollPosition: .init())
        } else {
            cell.setSelectedIcon(data.type, isSelected: false)
        }
        
        return cell
    }
    
    private func setupBalanceLabel(gameId: String) {
        let isHidden = playerViewModel.getBalanceHiddenState(gameId: gameId)
        setBalanceLabel(isHidden)
    }
    
    private func updateBalanceLabel(isHidden: Bool) {
        setBalanceLabel(isHidden)
        playerViewModel.saveBalanceHiddenState(gameId: self.gameId, isHidden: isBalanceLabelHidden)
    }
    
    private func setBalanceLabel(_ isHidden: Bool) {
        isBalanceLabelHidden = isHidden
        
        if isBalanceLabelHidden {
            btnBalanceHide.setTitle(Localize.string("common_show"), for: .normal)
            labBalance.text = "\(balanceSummary.first ?? " ") •••••••"
        }
        else {
            btnBalanceHide.setTitle(Localize.string("common_hide"), for: .normal)
            labBalance.text = balanceSummary
        }
    }
}

// MARK: - Binding

extension SideBarViewController {
    
    private func dataBinding() {
        balanceBinding()
        playerInfoBinding()
        productsListBinding()
        maintenanceStatusBinding()
        errorsHandingBinding()
    }
    
    private func balanceBinding() {
          sideMenuViewModel!
            .observePlayerBalance()
            .map { (currency: AccountCurrency) -> String in
                return "\(currency.symbol) \(currency.formatString())"
            }
            .subscribe(onNext: { [weak self] balanceSummary in
                guard let self = self else { return }
                
                self.balanceSummary = balanceSummary
                self.updateBalanceLabel(isHidden: self.isBalanceLabelHidden)
            })
            .disposed(by: disposeBag)
    }
    
    private func playerInfoBinding() {
        refreshTrigger
            .asDriver(onErrorJustReturn: Void())
            .flatMapLatest { [weak self] _ -> Driver<(Player?, AccountCurrency?)> in
                guard let self = self else { return .just((nil, nil)) }
                
                return self.playerViewModel.getPlayerInfo()
                    .zip(with: self.playerViewModel.getBalance()) { (player, accountCurrency) in
                        return (player, accountCurrency)
                    }
                    .asDriver(onErrorJustReturn: (nil, nil))
            }
            .filter { (player, accountCurrency) in
                return player != nil && accountCurrency != nil
            }
            .map { (player, accountCurrency) in
                return (player!, accountCurrency!)
            }
            .map { ($0, "\($1.symbol) \($1.formatString())") }
            .do(onNext: { [weak self] (player, balanceSummary) in
                guard let self = self else { return }
                
                if self.sideMenuViewModel!.currentSelectedProductType == nil {
                    self.sideMenuViewModel!.currentSelectedProductType = player.defaultProduct
                }
                
                self.gameId = player.gameId
                self.balanceSummary = balanceSummary
                
                self.updatePlayerInfoUI(player)
                self.setupBalanceLabel(gameId: player.gameId)
            })
            .filter { (player, _) in
                player.defaultProduct != nil
            }
            .map { (player, _) -> ProductType in
                player.defaultProduct!
            }
            .drive(serviceViewModel.input.playerDefaultProductType)
            .disposed(by: disposeBag)
    }
    
  private func productsListBinding() {
        refreshTrigger
            .asDriver(onErrorJustReturn: Void())
            .flatMapLatest({ [weak self] _ -> Driver<[(productType: ProductType, maintainTime: OffsetDateTime?)]?> in
                guard let self = self else { return .just(nil) }
                
                return self.getProductsMaintenanceTime()
            })
            .compactMap { $0 }
            .map { [weak self] (productsMaintainTimeArray: [(productType: ProductType, maintainTime: OffsetDateTime?)])
              -> [ProductItem] in
              guard let self
              else { return [] }

              return self.sideMenuViewModel!.products
                .map { (product: ProductItem) -> ProductItem in
                        return ProductItem(
                            title: product.title,
                            image: product.image,
                            type: product.type,
                            maintainTime: productsMaintainTimeArray.first(where: { $0.productType == product.type })?.maintainTime
                        )
                    }
            }
            .filter({ !$0.isEmpty })
            .do(afterNext: { [weak self] _ in
                self?.listProduct.reloadData()
            })
            .drive(self.listProduct.rx.items) { [weak self] collection, row, data in
                guard let self = self else { return .init() }

                return self.updateProductListCell(view: collection, at: row, source: data)
            }
            .disposed(by: disposeBag)
    }
    
    private func getProductsMaintenanceTime() -> Driver<[(productType: ProductType, maintainTime: OffsetDateTime?)]?> {
        serviceViewModel.output.productsMaintainTime
            .map { $0 }
            .asDriver(onErrorRecover: { [weak self] error in
                self?.playerViewModel.errorsSubject
                    .onNext(error)
                
                return .just(nil)
            })
    }
    
    private func maintenanceStatusBinding() {
      sideMenuViewModel!
        .observeMaintenanceStatus()
        .subscribe(onNext: { [weak self] status in
            guard let self else { return }
          
            self.updateMaintainStatus(status)
            self.refreshTrigger.onNext(Void())
        })
        .disposed(by: disposeBag)
    }
  
    private func updateMaintainStatus(_ status: MaintenanceStatus) {
        switch status {
        case is MaintenanceStatus.AllPortal:
          alertAndExitLobby(KickOutSignal.Maintenance)
        case let productStatus as MaintenanceStatus.Product:
            productMaintenanceStatus = productStatus
        default:
            break
        }
    }
    
    fileprivate func eventHandler() {
        Observable.zip(listProduct.rx.itemSelected, listProduct.rx.modelSelected(ProductItem.self)).bind { [weak self] (indexPath, data) in
            guard let self = self else { return }
            NavigationManagement.sharedInstance.goTo(productType: data.type, isMaintenance: self.productMaintenanceStatus?.isProductMaintain(productType: data.type) ?? false)
            let cell = self.listProduct.cellForItem(at: indexPath) as? ProductItemCell
            cell?.setSelectedIcon(data.type, isSelected: true)
            self.sideMenuViewModel!.currentSelectedProductType = data.type
        }.disposed(by: disposeBag)
        
        Observable.zip(listProduct.rx.itemDeselected, listProduct.rx.modelDeselected(ProductItem.self)).bind { [weak self] (indexPath, data) in
            let cell = self?.listProduct.cellForItem(at: indexPath) as? ProductItemCell
            cell?.setSelectedIcon(data.type, isSelected: false)
        }.disposed(by: disposeBag)
        
        Observable.zip(listFeature.rx.itemSelected, listFeature.rx.modelSelected(FeatureItem.self)).bind {[weak self] (indexPath, data) in
            let featureType = data.type
            if featureType != .logout {
                self?.cleanProductSelected()
            }
            
            switch featureType {
            case .logout:
                self?.alertAndExitLobby(nil, cancel: {})
            case .withdraw:
                NavigationManagement.sharedInstance.goTo(storyboard: "Withdrawal", viewControllerId: "WithdrawalNavigation")
            case .deposit:
                NavigationManagement.sharedInstance.goTo(storyboard: "Deposit", viewControllerId: "DepositNavigation")
            case .callService:
                NavigationManagement.sharedInstance.goTo(storyboard: "CustomService", viewControllerId: "CustomerServiceMainNavigationController")
            }
            
            self?.listFeature.deselectRow(at: indexPath, animated: true)
        }.disposed(by: disposeBag)
        
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
    
    private func errorsHandingBinding() {
        playerViewModel.errors()
            .subscribe(onNext: { [weak self] error in
                self?.handleErrors(error)
            })
            .disposed(by: disposeBag)
      
        sideMenuViewModel!.errors()
          .subscribe(onNext: { [weak self] error in
              self?.handleErrors(error)
          })
          .disposed(by: disposeBag)
    }
}

// MARK: - Touch Event

extension SideBarViewController {
    
    @IBAction func btnClosePressed(_ sender : UIButton)  {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnHideBalance(_ sender : UIButton) {
        updateBalanceLabel(isHidden: !isBalanceLabelHidden)
    }
    
    @IBAction func btnRefreshBalance(_ sender : UIButton) {
        sideMenuViewModel!.fetchPlayerBalance()
    }
    
    @objc func accountTap(_ sender: UITapGestureRecognizer) {
        let rootVC = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.rootViewController
        NavigationManagement.sharedInstance.previousRootViewController = rootVC
        NavigationManagement.sharedInstance.navigateToAuthorization()
    }
    
    @objc func accountLevelTap(_ sender: UITapGestureRecognizer) {
        cleanProductSelected()
        NavigationManagement.sharedInstance.goTo(storyboard: "LevelPrivilege", viewControllerId: "LevelPrivilegeNavigationController")
    }
    
    @objc func balanceTap(_ sender: UITapGestureRecognizer) {
        cleanProductSelected()
        NavigationManagement.sharedInstance.goTo(storyboard: "TransactionLog", viewControllerId: "TransactionLogNavigation")
    }
    
    @IBAction func toGift(_ sender : UIButton){
        cleanProductSelected()
        NavigationManagement.sharedInstance.goTo(storyboard: "Promotion", viewControllerId: "PromotionNavigationController")
    }
    
    @IBAction func toNotify(_ sender : UIButton){
        cleanProductSelected()
        NavigationManagement.sharedInstance.goTo(storyboard: "Notification", viewControllerId: "AccountNotificationNavigationController")
    }
    
    @IBAction func manualUpdate() {
        if Configuration.manualUpdate {
            Configuration.isAutoUpdate = true
        }
    }
}

// MARK: - SideMenuNavigationControllerDelegate

extension SideBarViewController: SideMenuNavigationControllerDelegate {
    
    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) {
        dataRefresh()
        CustomServicePresenter.shared.isInSideMenu = true
    }
    
    func sideMenuWillDisappear(menu: SideMenuNavigationController, animated: Bool) {
        CustomServicePresenter.shared.isInSideMenu = false
    }
}
