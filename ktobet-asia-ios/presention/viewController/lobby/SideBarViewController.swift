import UIKit
import RxSwift
import RxCocoa
import share_bu
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
    
    // MARK: BUTTON EVENT
    @IBAction func btnClosePressed(_ sender : UIButton)  {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnHideBalance(_ sender : UIButton) {
        setBalanceHiddenState(isHidden: !viewModel.getBalanceHiddenState(gameId: player?.gameId ?? ""))
    }
    
    @IBAction func btnRefreshBalance(_ sender : UIButton) {
        setBalanceHiddenState(isHidden: false)
        viewModel.getBalance().bind(to: labBalance.rx.text).disposed(by: disposeBag)
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.disposeSystemNotify(_:)), name: NSNotification.Name(rawValue: "disposeSystemNotify"), object: nil)
        disposableNotify = systemViewModel.observeSystemMessage().subscribe {(target: Target) in
            switch target {
            case .Kickout:
                Alert.show(Localize.string("common_notify_logout_title"), Localize.string("common_notify_logout_content"), confirm: {
                    self.viewModel.logout()
                        .subscribeOn(MainScheduler.instance)
                        .subscribe(onCompleted: {
                            self.systemViewModel.disconnectService()
                            self.disposableNotify?.dispose()
                            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
                        }).disposed(by: self.disposeBag)
                    self.systemViewModel.disconnectService()
                    self.disposableNotify?.dispose()
                }, cancel: nil)
            default:
                break
            }
        }
    }
    
    @objc func disposeSystemNotify(_ notification: Notification) {
        self.systemViewModel.disconnectService()
        self.disposableNotify?.dispose()
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
            flowLayout.itemSize = CGSize(width: width, height: 108)
            flowLayout.minimumLineSpacing = space
            flowLayout.minimumInteritemSpacing = space
            return flowLayout
        }()
        
        labBalance.numberOfLines = 0
        labBalance.lineBreakMode = .byCharWrapping
        labUserAcoount.numberOfLines = 0
        labUserAcoount.lineBreakMode = .byCharWrapping
    }
    
    fileprivate func dataBinding() {
        viewModel.loadPlayerInfo().subscribe {[weak self] (player) in
            guard let self = self else { return }
            self.player = player
            self.labUserLevel.text = "LV\(player.playerInfo.level)"
            self.labUserAcoount.text = "\(AccountMask.maskAccount(account: player.playerInfo.displayId))"
            self.labUserName.text = "\(player.playerInfo.realName)"
            self.slideViewModel.arrProducts.bind(to: self.listProduct.rx.items(cellIdentifier: String(describing: ProductItemCell.self), cellType: ProductItemCell.self)) { index, data, cell in
                cell.setup(data)
                if let defaultProduct = player.defaultProduct {
                    if defaultProduct == data.type {
                        cell.setSelectedIcon(data.type, isSelected: true)
                        self.slideViewModel.currentSelectedCell = cell
                        self.slideViewModel.currentSelectedProductType = data.type
                        self.listProduct.selectItem(at: IndexPath(item: index, section: 0), animated: true, scrollPosition: .init())
                    }
                }
            }.disposed(by: self.disposeBag)
        } onError: {(error) in
            let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
            toastView.show(on: self.view, statusTip: String(format: Localize.string("common_unknownerror"), "\((error as NSError).code)"), img: UIImage(named: "Failed"))
        }.disposed(by: disposeBag)
        
        viewModel.getBalance().subscribe {[unowned self] (balance) in
            self.labBalance.text = balance
            self.viewModel.balance = balance
            self.setBalanceHiddenState(isHidden: self.viewModel.getBalanceHiddenState(gameId: self.player?.gameId ?? ""))
        } onError: { (error) in
            let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
            toastView.show(on: self.view, statusTip: String(format: Localize.string("common_unknownerror"), "\((error as NSError).code)"), img: UIImage(named: "Failed"))
        }.disposed(by: disposeBag)
        
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
        
        listFeature.rx.modelSelected(FeatureItem.self).subscribe {(data) in
            guard let featureType = data.element?.name else { return }
            if featureType != .logout {
                if let productType = self.slideViewModel.currentSelectedProductType {
                    self.slideViewModel.currentSelectedCell?.setSelectedIcon(productType, isSelected: false)
                }
            }
            
            switch featureType {
            case .logout:
                self.viewModel.logout()
                    .subscribeOn(MainScheduler.instance)
                    .subscribe(onCompleted: {
                        Alert.show(Localize.string("common_tip_title_warm"), Localize.string("common_confirm_logout"), confirm: {
                            NotificationCenter.default.post(Notification(name: Notification.Name("disposeSystemNotify")))
                            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
                        }, cancel: {
                            
                        }, tintColor: UIColor.red)
                    }).disposed(by: self.disposeBag)
            case .withdraw:
                NavigationManagement.sharedInstance.goTo(storyboard: "Game", viewControllerId: "WithdrawNavigationController")
            case .diposit:
                NavigationManagement.sharedInstance.goTo(storyboard: "Game", viewControllerId: "DepositNavigationController")
            case .callService:
                NavigationManagement.sharedInstance.goTo(storyboard: "Game", viewControllerId: "CallServiceNavigationController")
            }
        }.disposed(by: disposeBag)
        
        let labAccountTap = UITapGestureRecognizer(target: self, action: #selector(self.accountTap(_:)))
        self.labUserAcoount.isUserInteractionEnabled = true
        self.labUserAcoount.addGestureRecognizer(labAccountTap)
        
        let labAccountLevelTap = UITapGestureRecognizer(target: self, action: #selector(self.accountLevelTap(_:)))
        self.labUserLevel.isUserInteractionEnabled = true
        self.labUserLevel.addGestureRecognizer(labAccountLevelTap)
        
        let labBalanceTap = UITapGestureRecognizer(target: self, action: #selector(self.balanceTap(_:)))
        self.labBalance.isUserInteractionEnabled = true
        self.labBalance.addGestureRecognizer(labBalanceTap)
    }
    
    @objc func accountTap(_ sender: UITapGestureRecognizer) {
        if let productType = self.slideViewModel.currentSelectedProductType {
            self.slideViewModel.currentSelectedCell?.setSelectedIcon(productType, isSelected: false)
        }
        NavigationManagement.sharedInstance.goTo(storyboard: "Game", viewControllerId: "AccountInfoNavigationController")
    }
    
    @objc func accountLevelTap(_ sender: UITapGestureRecognizer) {
        setUnSelectProduct()
        NavigationManagement.sharedInstance.goTo(storyboard: "Game", viewControllerId: "AccountLevelNavigationController")
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
