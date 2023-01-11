import UIKit
import RxSwift
import SharedBu

class ArcadeViewController: DisplayProduct {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tagsStackView: GameTagStackView!
    @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
    @IBOutlet private weak var scrollViewContentHeight: NSLayoutConstraint!
    
    @Injected private var loading: Loading
    
    private lazy var viewModel = Injectable.resolve(ArcadeViewModel.self)!
    private var disposeBag = DisposeBag()
    
    var barButtonItems: [UIBarButtonItem] = []
    
    lazy var gameDataSourceDelegate = { return ProductGameDataSourceDelegate(self) }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Logger.shared.info("\(type(of: self)) viewDidLoad.")
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
        self.bind(position: .right, barButtonItems: .kto(.search), .kto(.favorite), .kto(.record))
        initUI()
        dataBinding()
    }
    
    private func initUI() {
        gamesCollectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    private func dataBinding() {
        viewModel.errors()
            .subscribe(onNext: {[weak self] in
                if $0.isMaintenance() {
                    NavigationManagement.sharedInstance.goTo(productType: .arcade, isMaintenance: true)
                } else {
                    self?.handleErrors($0)
                }
            })
            .disposed(by: disposeBag)
        
        bindWebGameResult(with: viewModel)
        
        viewModel.activityIndicator
            .bind(to: loading)
            .disposed(by: disposeBag)
        
        viewModel
            .gameSource
            .subscribe(onNext: { [weak self] (games) in
                self?.reloadGameData(games)
            })
            .disposed(by: disposeBag)
        
        viewModel.tagStates
            .subscribe(onNext: { [unowned self] (data) in
                self.tagsStackView.initialize(
                    recommend: data.0,
                    new: data.1,
                    allTagClick: { self.viewModel.selectAll() },
                    recommendClick: { self.viewModel.toggleRecommend() },
                    newClick: { self.viewModel.toggleNew() })
            })
            .disposed(by: self.disposeBag)
    }
    
    
    // MARK: KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize", let newvalue = change?[.newKey] {
            if let obj = object as? UICollectionView , obj == gamesCollectionView {
                let aboveHeight = titleLabel.frame.size.height + tagsStackView.frame.size.height
                let space: CGFloat = 8 + 30 + 24 + 20
                scrollViewContentHeight.constant = (newvalue as! CGSize).height + aboveHeight + space
            }
        }
    }
    
    // MARK: ProductBaseCollection
    func setCollectionView() -> UICollectionView {
        return gamesCollectionView
    }
    
    func setProductGameDataSourceDelegate() -> ProductGameDataSourceDelegate {
        return gameDataSourceDelegate
    }
    
    func setViewModel() -> DisplayProductViewModel? {
        return viewModel
    }
    
    override func setProductType() -> ProductType {
        .arcade
    }
}

extension ArcadeViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        switch sender {
        case is RecordBarButtonItem:
            guard let betSummaryViewController = self.storyboard?.instantiateViewController(withIdentifier: "ArcadeSummaryViewController") as? ArcadeSummaryViewController else { return }
            self.navigationController?.pushViewController(betSummaryViewController, animated: true)
            break
        case is FavoriteBarButtonItem:
            guard let favoriteViewController = UIStoryboard(name: "Product", bundle: nil).instantiateViewController(withIdentifier: "FavoriteViewController") as? FavoriteViewController else { return }
            favoriteViewController.viewModel = self.viewModel
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
