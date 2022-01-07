import UIKit
import RxSwift
import RxCocoa
import SharedBu
import SideMenu

extension SideBarViewController: SideMenuNavigationControllerDelegate {
    func sideMenuWillAppear(menu: SideMenuNavigationController, animated: Bool) {
        dataRefresh()
        CustomServicePresenter.shared.isInSideMenu = true
        CustomServicePresenter.shared.hiddenServiceIcon()
    }
    
    func sideMenuWillDisappear(menu: SideMenuNavigationController, animated: Bool) {
        CustomServicePresenter.shared.isInSideMenu = false
        CustomServicePresenter.shared.showServiceIcon()
    }
}

class SideBarViewController: UIViewController {
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
    
    private var player : Player?
    private var disposeBag = DisposeBag()
    private var disposableNotify: Disposable?
    private var viewModel = DI.resolve(PlayerViewModel.self)!
    private var systemViewModel = DI.resolve(SystemViewModel.self)!
    private var serviceViewModel = DI.resolve(ServiceStatusViewModel.self)!
    private var slideViewModel = SlideMenuViewModel()
    private var refreshTrigger = PublishSubject<()>()
    private var productMaintenanceStatus: MaintenanceStatus.Product?

    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        initProducts()
        initFeatures()
        eventHandler()
        dataBinding()
        
        guard let menu = navigationController as? SideMenuNavigationController, menu.blurEffectStyle == nil else {
            return
        }
        
        menu.sideMenuDelegate = self
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.whiteFull]
            appearance.backgroundColor = UIColor.backgroundSidebarMineShaftGray
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
    }
    
    deinit {
        disposeSystemNotify()
    }
    
    // MARK: BUTTON EVENT
    @IBAction func btnClosePressed(_ sender : UIButton)  {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnHideBalance(_ sender : UIButton) {
        setBalanceHiddenState(isHidden: !viewModel.getBalanceHiddenState(gameId: player?.gameId ?? ""))
    }
    
    @IBAction func btnRefreshBalance(_ sender : UIButton) {
        setBalanceHiddenState(isHidden: false)
        viewModel.refreshBalance.onNext(())
    }
    
    // MARK: KVO
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
    
    func observeSystemMessage() {
        disposableNotify = systemViewModel.observeSystemMessage().subscribe {[weak self](target: Target) in
            guard let self = self else { return }
            switch target {
            case .Kickout(let type):
                self.alertAndLogout(type)
            case .Balance:
                self.viewModel.refreshBalance.onNext(())
            case .Maintenance:
                self.serviceViewModel.refreshProductStatus()
            }
        }
    }
    
    fileprivate func disposeSystemNotify() {
        self.systemViewModel.disconnectService()
        self.disposableNotify?.dispose()
    }
    
    fileprivate func alertAndLogout(_ type: KickOutType?, cancel: (() -> ())? = nil) {
        var title = Localize.string("common_tip_title_warm")
        var meesage = ""
        switch type {
        case .duplicatedLogin:
            meesage = Localize.string("common_notify_logout_content")
        case .Suspend:
            meesage = Localize.string("common_kick_out_suspend")
        case .Inactive:
            meesage = Localize.string("common_kick_out_inactive")
        case .Maintenance:
            title = Localize.string("common_urgent_maintenance")
            meesage = Localize.string("common_maintenance_logout")
        case .TokenExpired:
            title = Localize.string("common_kick_out_token_expired_title")
            meesage = Localize.string("common_kick_out_token_expired")
        default:
            title = Localize.string("common_tip_title_warm")
            meesage = Localize.string("common_confirm_logout")
        }
        
        Alert.show(title, meesage, confirm: {[weak self] in
            guard let self = self else { return }
            CustomServicePresenter.shared.closeChatRoom()
            self.viewModel.logout()
                .subscribeOn(MainScheduler.instance)
                .subscribe(onCompleted: {
                    NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
                }).disposed(by: self.disposeBag)
        }, cancel: cancel)
    }
    
    fileprivate func setBalanceHiddenState(isHidden: Bool) {
        if isHidden {
            btnBalanceHide.setTitle(Localize.string("common_show"), for: .normal)
            labBalance.text = "\(viewModel.balance?.first ?? " ") •••••••"
        } else {
            btnBalanceHide.setTitle(Localize.string("common_hide"), for: .normal)
            labBalance.text = viewModel.balance
        }
        viewModel.saveBalanceHiddenState(gameId: player?.gameId ?? "", isHidden: isHidden)
    }
    
    fileprivate func initUI() {
        let navigationBar = navigationController?.navigationBar
        navigationBar?.barTintColor = UIColor.backgroundSidebarMineShaftGray
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
            flowLayout.itemSize = CGSize(width: width, height: 84)
            flowLayout.minimumLineSpacing = 12
            flowLayout.minimumInteritemSpacing = space
            return flowLayout
        }()
        
        labBalance.numberOfLines = 0
        labBalance.lineBreakMode = .byCharWrapping
        labUserAcoount.numberOfLines = 0
        labUserAcoount.lineBreakMode = .byCharWrapping
    }
    
    fileprivate func dataBinding() {
        viewModel.playerBalance.drive {[unowned self] _ in
            self.setBalanceHiddenState(isHidden: self.viewModel.getBalanceHiddenState(gameId: self.player?.gameId ?? ""))
        }.disposed(by: disposeBag)
        
        let shareLoadPlayerInfo = refreshTrigger.flatMapLatest {[weak self] _ -> Observable<Player> in
            guard let self = self else { return Observable.error(KTOError.EmptyData)}
            return self.viewModel.loadPlayerInfo().asObservable()
        }.share(replay: 1)
        
        shareLoadPlayerInfo.compactMap{ $0.defaultProduct }.bind(to: serviceViewModel.input.playerDefaultProduct).disposed(by: disposeBag)
        serviceViewModel.output.maintainDefaultType.drive(onNext: {[weak self] maintainType in
            if self?.slideViewModel.currentSelectedProductType == nil {
                self?.slideViewModel.currentSelectedProductType = maintainType
            }
            
            self?.listProduct.reloadData()
        }).disposed(by: disposeBag)
        
        serviceViewModel.output.portalMaintenanceStatus.drive(onNext: {[weak self] status in
            self?.updateMaintainStatus(status)
        }).disposed(by: disposeBag)
        
        shareLoadPlayerInfo.subscribe(onNext: { [weak self] (player) in
            guard let self = self else { return }
            self.player = player
            self.labUserLevel.text = "LV\(player.playerInfo.level)"
            self.labUserAcoount.text = "\(AccountMask.maskAccount(account: player.playerInfo.displayId))"
            self.labUserName.text = "\(player.playerInfo.gameId)"
        }, onError: { [weak self] (error) in
            self?.handleUnknownError(error)
        }).disposed(by: self.disposeBag)
    }
    
    private func updateMaintainStatus(_ status: MaintenanceStatus) {
        switch status {
        case is MaintenanceStatus.AllPortal:
            alertAndLogout(KickOutType.Maintenance)
        case let productStatus as MaintenanceStatus.Product:
            productMaintenanceStatus = productStatus
        default:
            break
        }
    }
    
    fileprivate func initProducts() {
        Observable.combineLatest(slideViewModel.arrProducts, serviceViewModel.output.maintainTimes)
            .map { (productItems, maintainTimes) in
                productItems.map { item in
                    ProductItem(title: item.title,
                                image: item.image,
                                type: item.type,
                                maintainTime: maintainTimes.first(where: { $0.productType == item.type })?.maintainTime) }
            }.bind(to: self.listProduct.rx.items(cellIdentifier: String(describing: ProductItemCell.self), cellType: ProductItemCell.self)) { [weak self] (index, data, cell) in
                guard let self = self else { return }
                cell.setup(data)
                cell.finishCountDown = { [weak self] in
                    self?.serviceViewModel.refreshProductStatus()
                }
                if let selectedProductType = self.slideViewModel.currentSelectedProductType, data.type == selectedProductType {
                    cell.setSelectedIcon(selectedProductType, isSelected: true)
                    self.listProduct.selectItem(at: IndexPath(item: index, section: 0), animated: true, scrollPosition: .init())
                } else {
                    cell.setSelectedIcon(data.type, isSelected: false)
                }
            }.disposed(by: disposeBag)
    }
    
    fileprivate func initFeatures() {
        slideViewModel.features.bind(to: listFeature.rx.items(cellIdentifier: String(describing: FeatureItemCell.self), cellType: FeatureItemCell.self)) { index, data, cell in
            cell.setup(data.name.rawValue, image: UIImage(named: data.icon))
        }.disposed(by: disposeBag)
    }
    
    fileprivate func dataRefresh() {
        refreshTrigger.onNext(())
        viewModel.refreshBalance.onNext(())
        serviceViewModel.refreshProductStatus()
    }
    
    fileprivate func eventHandler() {
        Observable.zip(listProduct.rx.itemSelected, listProduct.rx.modelSelected(ProductItem.self)).bind { [weak self] (indexPath, data) in
            guard let self = self else { return }
            NavigationManagement.sharedInstance.goTo(productType: data.type, isMaintenance: self.productMaintenanceStatus?.isProductMaintain(productType: data.type) ?? false)
            let cell = self.listProduct.cellForItem(at: indexPath) as? ProductItemCell
            cell?.setSelectedIcon(data.type, isSelected: true)
            self.slideViewModel.currentSelectedProductType = data.type
        }.disposed(by: disposeBag)
        
        Observable.zip(listProduct.rx.itemDeselected, listProduct.rx.modelDeselected(ProductItem.self)).bind { [weak self] (indexPath, data) in
            let cell = self?.listProduct.cellForItem(at: indexPath) as? ProductItemCell
            cell?.setSelectedIcon(data.type, isSelected: false)
        }.disposed(by: disposeBag)
        
        Observable.zip(listFeature.rx.itemSelected, listFeature.rx.modelSelected(FeatureItem.self)).bind {[weak self] (indexPath, data) in
            let featureType = data.name
            if featureType != .logout {
                self?.cleanProductSelected()
            }
            
            switch featureType {
            case .logout:
                self?.alertAndLogout(nil, cancel: {})
            case .withdraw:
                NavigationManagement.sharedInstance.goTo(storyboard: "Withdrawal", viewControllerId: "WithdrawalNavigation")
            case .diposit:
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
    
    @objc func accountTap(_ sender: UITapGestureRecognizer) {
        cleanProductSelected()
        NavigationManagement.sharedInstance.goTo(storyboard: "AccountInfo", viewControllerId: "AccountInfoNavigationController")
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
        NavigationManagement.sharedInstance.goTo(storyboard: "Notify", viewControllerId: "AccountNotifyNavigationController")
    }
    
    fileprivate func cleanProductSelected() {
        self.slideViewModel.currentSelectedProductType = nil
        self.listProduct.reloadData()
    }
}
