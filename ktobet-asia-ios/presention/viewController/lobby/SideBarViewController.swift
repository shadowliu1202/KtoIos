import UIKit
import RxSwift
import RxCocoa
import SharedBu
import SideMenu

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
    private var slideViewModel = SlideMenuViewModel()
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        dataBinding()
        eventHandler()
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
            meesage = Localize.string("common_kick_out_maintenance")
        case .TokenExpired:
            title = Localize.string("common_kick_out_token_expired_title")
            meesage = Localize.string("common_kick_out_token_expired")
        default:
            title = Localize.string("common_tip_title_warm")
            meesage = Localize.string("common_confirm_logout")
        }
        
        Alert.show(title, meesage, confirm: {[weak self] in
            guard let self = self else { return }
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
            viewModel.saveBalanceHiddenState(gameId: player?.gameId ?? "", isHidden: isHidden)
            viewModel.balance = labBalance.text
            labBalance.text = "\(viewModel.balance?.first ?? " ") *******"
        } else {
            btnBalanceHide.setTitle(Localize.string("common_hide"), for: .normal)
            viewModel.saveBalanceHiddenState(gameId: player?.gameId ?? "", isHidden: isHidden)
            labBalance.text = viewModel.balance
        }
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
        let shareLoadPlayerInfo = self.viewModel.loadPlayerInfo().share()
        self.rx.viewWillAppear.flatMap({ (_) in
            return shareLoadPlayerInfo
        }).subscribe(onNext: { [weak self] (player) in
            guard let self = self else { return }
            self.player = player
            self.labUserLevel.text = "LV\(player.playerInfo.level)"
            self.labUserAcoount.text = "\(AccountMask.maskAccount(account: player.playerInfo.displayId))"
            self.labUserName.text = "\(player.playerInfo.gameId)"
        }, onError: { [weak self] (error) in
            self?.handleUnknownError(error)
        }).disposed(by: self.disposeBag)
        
        shareLoadPlayerInfo.flatMapLatest({ [weak self] (player) -> Observable<[ProductItem]> in
            guard let self = self else { return Observable<[ProductItem]>.just([]) }
            return self.slideViewModel.arrProducts
        }).catchError({ [weak self] (error) -> Observable<[ProductItem]> in
            self?.handleUnknownError(error)
            return Observable<[ProductItem]>.just([])
        }).bind(to: self.listProduct.rx.items(cellIdentifier: String(describing: ProductItemCell.self), cellType: ProductItemCell.self)) {[weak self] (index, data, cell) in
            guard let self = self else { return }
            cell.setup(data)
            if let defaultProduct = self.player?.defaultProduct {
                if defaultProduct == data.type {
                    cell.setSelectedIcon(data.type, isSelected: true)
                    self.slideViewModel.currentSelectedCell = cell
                    self.slideViewModel.currentSelectedProductType = data.type
                    self.listProduct.selectItem(at: IndexPath(item: index, section: 0), animated: true, scrollPosition: .init())
                }
            }
        }.disposed(by: self.disposeBag)
        
        viewModel.playerBalance.subscribe {[unowned self] (balance) in
            let paragraph = NSMutableParagraphStyle()
            paragraph.firstLineHeadIndent = 0
            paragraph.headIndent = 16
            paragraph.lineBreakMode = .byCharWrapping
            let mutString = NSAttributedString(
                string: balance,
                attributes: [NSAttributedString.Key.paragraphStyle: paragraph]
            )

            self.labBalance.attributedText = mutString
            self.labBalance.text = balance
            self.viewModel.balance = balance
            self.setBalanceHiddenState(isHidden: self.viewModel.getBalanceHiddenState(gameId: self.player?.gameId ?? ""))
        } onError: {[weak self] (error) in
            self?.handleUnknownError(error)
        }.disposed(by: disposeBag)
        
        viewModel.playerBalance.bind(to: self.labBalance.rx.text).disposed(by: self.disposeBag)
        viewModel.refreshBalance.onNext(())
        
        slideViewModel.features.bind(to: listFeature.rx.items(cellIdentifier: String(describing: FeatureItemCell.self), cellType: FeatureItemCell.self)) { index, data, cell in
            cell.setup(data.name.rawValue, image: UIImage(named: data.icon))
        }.disposed(by: disposeBag)
        
        listProduct.reloadData()
        listFeature.reloadData()
    }
    
    fileprivate func eventHandler() {
        Observable.zip(listProduct.rx.itemSelected, listProduct.rx.modelSelected(ProductItem.self)).bind { [weak self] (indexPath, data) in
            NavigationManagement.sharedInstance.goTo(productType: data.type)
            let cell = self?.listProduct.cellForItem(at: indexPath) as? ProductItemCell
            cell?.setSelectedIcon(data.type, isSelected: true)
            self?.slideViewModel.currentSelectedCell = cell
            self?.slideViewModel.currentSelectedProductType = data.type
        }.disposed(by: disposeBag)
        
        Observable.zip(listProduct.rx.itemDeselected, listProduct.rx.modelDeselected(ProductItem.self)).bind { [weak self] (indexPath, data) in
            let cell = self?.listProduct.cellForItem(at: indexPath) as? ProductItemCell
            cell?.setSelectedIcon(data.type, isSelected: false)
        }.disposed(by: disposeBag)
        
        Observable.zip(listFeature.rx.itemSelected, listFeature.rx.modelSelected(FeatureItem.self)).bind {[weak self] (indexPath, data) in
            let featureType = data.name
            if featureType != .logout {
                if let productType = self?.slideViewModel.currentSelectedProductType {
                    self?.slideViewModel.currentSelectedCell?.setSelectedIcon(productType, isSelected: false)
                }
            }
            
            switch featureType {
            case .logout:
                self?.alertAndLogout(nil, cancel: {})
            case .withdraw:
                NavigationManagement.sharedInstance.goTo(storyboard: "Withdrawal", viewControllerId: "WithdrawalNavigation")
            case .diposit:
                NavigationManagement.sharedInstance.goTo(storyboard: "Deposit", viewControllerId: "DepositNavigation")
            case .callService:
                NavigationManagement.sharedInstance.goTo(storyboard: "Game", viewControllerId: "CallServiceNavigationController")
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
        if let productType = self.slideViewModel.currentSelectedProductType {
            self.slideViewModel.currentSelectedCell?.setSelectedIcon(productType, isSelected: false)
        }
        NavigationManagement.sharedInstance.goTo(storyboard: "Game", viewControllerId: "AccountInfoNavigationController")
    }
    
    @objc func accountLevelTap(_ sender: UITapGestureRecognizer) {
        setUnSelectProduct()
        NavigationManagement.sharedInstance.goTo(storyboard: "LevelPrivilege", viewControllerId: "LevelPrivilegeNavigationController")
    }
    
    @objc func balanceTap(_ sender: UITapGestureRecognizer) {
        setUnSelectProduct()
        NavigationManagement.sharedInstance.goTo(storyboard: "Game", viewControllerId: "AccountBalanceNavigationController")
    }
    
    @IBAction func toGift(_ sender : UIButton){
        setUnSelectProduct()
        NavigationManagement.sharedInstance.goTo(storyboard: "Game", viewControllerId: "AccountGiftNavigationController")
    }
    
    @IBAction func toNotify(_ sender : UIButton){
        setUnSelectProduct()
        NavigationManagement.sharedInstance.goTo(storyboard: "Game", viewControllerId: "AccountNotifyNavigationController")
    }
    
    fileprivate func setUnSelectProduct() {
        if let productType = self.slideViewModel.currentSelectedProductType {
            self.slideViewModel.currentSelectedCell?.setSelectedIcon(productType, isSelected: false)
        }
    }
}
