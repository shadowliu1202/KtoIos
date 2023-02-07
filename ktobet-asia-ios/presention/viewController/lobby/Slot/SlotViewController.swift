import UIKit
import RxSwift
import RxCocoa
import SharedBu
import SDWebImage
import TYCyclePagerView
import AlignedCollectionViewFlowLayout

class SlotViewController: ProductsViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var recentlyCollectionView: LoadMoreCollectionView!
    @IBOutlet var newCollectionView: LoadMoreCollectionView!
    @IBOutlet var jackpotCollectionView: LoadMoreCollectionView!
    @IBOutlet private weak var jackpotCollectionViewHeightConstant: NSLayoutConstraint!
    @IBOutlet var recentlyView: UIView!
    @IBOutlet var newView: UIView!
    @IBOutlet var jackpotView: UIView!
    @IBOutlet weak var blurImageBackgroundView: UIImageView!
    @IBOutlet var recentlyViewHeight: NSLayoutConstraint!
    @IBOutlet var recentlyViewTop: NSLayoutConstraint!
    @IBOutlet var newViewHeight: NSLayoutConstraint!
    @IBOutlet var jackpotViewHeight: NSLayoutConstraint!
    
    private var viewDidRotate = BehaviorRelay<Bool>.init(value: false)
    private var disposeBag = DisposeBag()
    
    var viewModel = Injectable.resolve(SlotViewModel.self)!
    
    var barButtonItems: [UIBarButtonItem] = []
    var datas = [SlotGame]()
    var maxGamesDisplay = 8
    lazy var gameDataSourceDelegate = { return ProductGameDataSourceDelegate(self, cellType: .loadMore) }()
    lazy var newGameDataSourceDelegate = { return ProductGameDataSourceDelegate(self, cellType: .loadMore) }()
    lazy var jackpotGameDataSourceDelegate = { return ProductGameDataSourceDelegate(self, cellType: .loadMore) }()
    
    lazy var pagerView: TYCyclePagerView = {
        let pagerView = TYCyclePagerView()
        pagerView.isInfiniteLoop = true
        pagerView.autoScrollInterval = 3.0
        pagerView.dataSource = self
        pagerView.delegate = self
        pagerView.register(TYCyclePagerViewCell.classForCoder(), forCellWithReuseIdentifier: "cellId")
        pagerView.backgroundView = UIImageView()
        return pagerView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Logger.shared.info("\(type(of: self)) viewDidLoad.")
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
        self.bind(position: .right, barButtonItems: .kto(.search), .kto(.favorite), .kto(.record))
        self.scrollView.addSubview(self.pagerView)
        self.recentlyCollectionView.registerCellFromNib(WebGameItemCell.className)
        self.recentlyCollectionView.tag = MoreGame.RecentPlay.rawValue
        self.newCollectionView.registerCellFromNib(WebGameItemCell.className)
        self.newCollectionView.tag = MoreGame.SlotNew.rawValue
        self.jackpotCollectionView.registerCellFromNib(WebGameItemCell.className)
        self.jackpotCollectionView.tag = MoreGame.Jackpot.rawValue
        
        jackpotCollectionView.contentInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 0)
        recentlyCollectionView.contentInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 0)
        newCollectionView.contentInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 0)
        bindingData()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.pagerView.frame = CGRect(x: 0, y: 66, width: self.view.frame.width, height: 240)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil, completion: { [weak self] _ in
            self?.viewDidRotate.accept(true)
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SlotAllViewController.segueIdentifier {
            if let dest = segue.destination as? SlotAllViewController {
                dest.viewModel = viewModel
            }
        }
        
        if segue.identifier == SlotSeeMoreViewController.segueIdentifier {
            if let dest = segue.destination as? SlotSeeMoreViewController {
                let tuple = sender as! (Int, [SlotGame])
                dest.type = MoreGame(rawValue: tuple.0)!
                dest.games = tuple.1
                dest.viewModel = self.viewModel
            }
        }
    }
    
    @IBAction func toAllSlot(_ sender: UIButton) {
        performSegue(withIdentifier: SlotAllViewController.segueIdentifier, sender: nil)
    }
    
    private func bindingData() {
        viewModel.popularGames
            .subscribe {[weak self] (slotGames) in
                guard let self = self,
                      let urlStr = slotGames.first?.thumbnail.url(),
                      let url = URL(string: urlStr) else {
                    self?.recentlyViewTop.constant = 30
                    self?.pagerView.isHidden = true
                    return
                }
                if self.datas.count == 0 && slotGames.count >= 3 {
                    self.addBlurBackgoundImageView(url: url)
                    self.pagerView.scrollToItem(at: 0, animate: false)
                }
                self.datas = slotGames
                if self.datas.count < 3 {
                    self.recentlyViewTop.constant = 30
                    self.pagerView.isHidden = true
                } else {
                    self.pagerView.reloadData()
                }
            } onError: {[weak self] (error) in
                self?.handleErrors(error)
            }
            .disposed(by: disposeBag)

        viewModel.errors()
            .subscribe(onNext: { [weak self] in
                self?.handleErrors($0)
            })
            .disposed(by: disposeBag)
        
        bindWebGameResult(with: viewModel)
        
        loadMoreCollectionView(delegate: gameDataSourceDelegate, collectionView: recentlyCollectionView, getGame: viewModel.recentGames, containerView: recentlyView, containerViewHeight: recentlyViewHeight)
        loadMoreCollectionView(delegate: newGameDataSourceDelegate, collectionView: newCollectionView, getGame: viewModel.newGames, containerView: newView, containerViewHeight: newViewHeight)
        loadMoreCollectionView(delegate: jackpotGameDataSourceDelegate, collectionView: jackpotCollectionView, getGame: viewModel.jackpotGames, containerView: jackpotView, containerViewHeight: jackpotViewHeight)
    }
    
    private func loadMoreCollectionView(delegate: ProductGameDataSourceDelegate, collectionView: UICollectionView, getGame: Observable<[SlotGame]>, containerView: UIView, containerViewHeight: NSLayoutConstraint) {
        collectionView.dataSource = delegate
        collectionView.delegate = delegate
        Observable.combineLatest(viewDidRotate, getGame).map{$1}
            .subscribe {[weak self] (slotGames) in
            guard let self = self else { return }
            if slotGames.count == 0 {
                containerView.isHidden = true
                containerViewHeight.constant = 0
            } else {
                delegate.lookMoreTap = {
                    self.performSegue(withIdentifier: SlotSeeMoreViewController.segueIdentifier, sender: (collectionView.tag, slotGames))
                }
                
                if slotGames.count > self.maxGamesDisplay {
                    delegate.isLookMore = true
                }
                
                delegate.setGames(Array(slotGames.prefix(8)))
                let contentOffset = collectionView.contentOffset
                collectionView.reloadData()
                collectionView.layoutIfNeeded()
                collectionView.setContentOffset(contentOffset, animated: false)
            }
        } onError: {[weak self] (error) in
            self?.handleErrors(error)
        }.disposed(by: disposeBag)
    }
    
    private func addBlurBackgoundImageView(url: URL) {
        let blur = SDImageBlurTransformer.init(radius: 16)
        blurImageBackgroundView.sd_setImage(url: url, context: [.imageTransformer : blur])
        
        let bottomGradient = CAGradientLayer()
        bottomGradient.startPoint = CGPoint(x: 0.5, y: 0.7)
        bottomGradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        bottomGradient.frame = blurImageBackgroundView.bounds
        let startColor = UIColor.clear.cgColor
        let endColor = UIColor.black131313.cgColor
        bottomGradient.colors = [startColor, endColor]
        blurImageBackgroundView.layer.insertSublayer(bottomGradient, at: 0)
        
        let topGradient = CAGradientLayer()
        topGradient.startPoint = CGPoint(x: 0.5, y: 0.3)
        topGradient.endPoint = CGPoint(x: 0.5, y: 0.0)
        topGradient.frame = blurImageBackgroundView.bounds
        let startColor1 = UIColor.clear.cgColor
        let endColor1 = UIColor.black131313.cgColor
        topGradient.colors = [startColor1, endColor1]
        blurImageBackgroundView.layer.insertSublayer(topGradient, at: 1)
    }
    
    private func showToast(_ action: FavoriteAction) {
        var text = ""
        var icon = UIImage(named: "")
        switch action {
        case .add:
            text = Localize.string("product_add_favorite")
            icon = UIImage(named: "add-favorite")
        case .remove:
            text = Localize.string("product_remove_favorite")
            icon = UIImage(named: "remove-favorite")
        }
        
        self.showToastOnCenter(ToastPopUp(icon: icon!, text: text))
    }
    
    override func setProductType() -> ProductType {
        .slot
    }
}

extension SlotViewController: TYCyclePagerViewDelegate, TYCyclePagerViewDataSource {
    func numberOfItems(in pageView: TYCyclePagerView) -> Int {
        return self.datas.count
    }
    
    func pagerView(_ pagerView: TYCyclePagerView, cellForItemAt index: Int) -> UICollectionViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cellId", for: index) as! TYCyclePagerViewCell
        if let url = URL(string: datas[index].thumbnail.url()) {
            cell.imageView.sd_setImage(url: url)
            cell.label.text = datas[index].gameName
            cell.button.setImage(datas[index].isFavorite ? UIImage(named: "game-favorite-active") : UIImage(named: "game-favorite-activeinactive"), for: .normal)
            cell.toggleFavorite = {[weak self] in
                guard let self = self else { return }
                self.viewModel.toggleFavorite(game: self.datas[index]) {[weak self] (action) in
                    self?.showToast(action)
                } onError: {[weak self] (error) in
                    self?.handleErrors(error)
                }
            }
        }
        
        return cell
    }
    
    func pagerView(_ pageView: TYCyclePagerView, didScrollFrom fromIndex: Int, to toIndex: Int) {
        guard let cell = pageView.curIndexCell() as? TYCyclePagerViewCell else { return }
        let blur = SDImageBlurTransformer.init(radius: 16)
        blurImageBackgroundView.image = cell.imageView.image != nil ? blur.transformedImage(with: cell.imageView.image!, forKey: "") : nil
    }
    
    func layout(for pageView: TYCyclePagerView) -> TYCyclePagerViewLayout {
        let layout = TYCyclePagerViewLayout()
        layout.itemSize = CGSize(width: 200, height: 200)
        layout.itemSpacing = 20
        layout.itemHorizontalCenter = true
        layout.layoutType = .linear
        return layout
    }
    
    func pagerView(_ pageView: TYCyclePagerView, didSelectedItemCell cell: UICollectionViewCell, at index: Int) {
        let slotGame = datas[index]
        viewModel.fetchGame(slotGame)
    }
}

extension SlotViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        switch sender {
        case is RecordBarButtonItem:
            guard let slotSummaryViewController = UIStoryboard(name: "Slot", bundle: nil).instantiateViewController(withIdentifier: "SlotSummaryViewController") as? SlotSummaryViewController else { return }
            self.navigationController?.pushViewController(slotSummaryViewController, animated: true)
            break
        case is FavoriteBarButtonItem:
            guard let favoriteViewController = UIStoryboard(name: "Product", bundle: nil).instantiateViewController(withIdentifier: "FavoriteViewController") as? FavoriteViewController else { return }
            favoriteViewController.viewModel = viewModel
            self.navigationController?.pushViewController(favoriteViewController, animated: true)
            break
        case is SearchButtonItem:
            guard let searchViewController = UIStoryboard(name: "Product", bundle: nil).instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController else { return }
            searchViewController.viewModel = self.viewModel
            self.navigationController?.pushViewController(searchViewController, animated: true)
            break
        default: break
        }
    }
}

extension SlotViewController: ProductVCProtocol {
    func toggleFavorite(_ game: WebGameWithDuplicatable, onCompleted: @escaping (FavoriteAction)->(), onError: @escaping (Error)->()) {
        viewModel.toggleFavorite(game: game, onCompleted: onCompleted, onError: onError)
    }

    func getProductViewModel() -> ProductWebGameViewModelProtocol? {
        return self.viewModel
    }
}
