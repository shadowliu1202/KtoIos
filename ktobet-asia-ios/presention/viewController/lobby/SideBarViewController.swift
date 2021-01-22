//
//  SideBarViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/5.
//

import UIKit
import RxSwift
import RxCocoa
import share_bu

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
    
    var productDidSelected : ((ProductType)->Void)?
    var player : Player?
    private var disposeBag = DisposeBag()
    private var viewModel = DI.resolve(PlayerViewModel.self)!
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
    }
    
    fileprivate func dataBinding() {
        if let player = player {
            labUserLevel.text = "LV\(player.playerInfo.level)"
            labUserAcoount.text = "\(AccountMask.maskAccount(account: player.playerInfo.displayId))"
            labUserName.text = "\(player.playerInfo.realName)"
        }
        
        viewModel.getBalance().subscribe(onNext: {[unowned self] balance in
            self.labBalance.text = balance
            self.viewModel.balance = balance
            self.setBalanceHiddenState(isHidden: self.viewModel.getBalanceHiddenState(gameId: self.player?.gameId ?? ""))
        }).disposed(by: disposeBag)
        
        slideViewModel.features.bind(to: listFeature.rx.items(cellIdentifier: String(describing: FeatureItemCell.self), cellType: FeatureItemCell.self)) { index, data, cell in
            cell.setup(data.name.rawValue, image: UIImage(named: data.icon))
        }.disposed(by: disposeBag)
        
        slideViewModel.arrProducts.bind(to: listProduct.rx.items(cellIdentifier: String(describing: ProductItemCell.self), cellType: ProductItemCell.self)) { index, data, cell in
            cell.setup(data.title, img: data.image)
        }.disposed(by: disposeBag)
        
        listProduct.reloadData()
        listFeature.reloadData()
    }
    
    fileprivate func eventHandler() {
        Observable.zip(listProduct.rx.itemSelected, listProduct.rx.modelSelected(ProductItem.self)).bind { [weak self] (indexPath, data) in
            self?.dismiss(animated: true) {
                self?.productDidSelected?(data.type)
            }
            
            let cell = self?.listProduct.cellForItem(at: indexPath) as? ProductItemCell
            cell?.imgIcon.backgroundColor = UIColor.redForDark502
        }.disposed(by: disposeBag)
        
        listProduct.rx.itemDeselected.subscribe { (indexPath) in
            guard let indexPath = indexPath.element else { return }
            let cell = self.listProduct.cellForItem(at: indexPath) as? ProductItemCell
            cell?.imgIcon.backgroundColor = UIColor.black
        }.disposed(by: disposeBag)
        
        listFeature.rx.modelSelected(FeatureItem.self).subscribe { (data) in
            guard let featureType = data.element?.name else { return }
            switch featureType {
            case .logout:
                self.viewModel.logout()
                    .subscribeOn(MainScheduler.instance)
                    .subscribe(onCompleted: {
                        Alert.show(Localize.string("common_tip_title_warm"), Localize.string("common_confirm_logout"), confirm: {
                            let story = UIStoryboard(name: "Login", bundle: nil)
                            UIApplication.shared.keyWindow?.rootViewController = story.instantiateInitialViewController()
                        }, cancel: {
                            
                        }, tintColor: UIColor.red)
                    }).disposed(by: self.disposeBag)
            default:
                break
            }
        }.disposed(by: disposeBag)
    }
}
