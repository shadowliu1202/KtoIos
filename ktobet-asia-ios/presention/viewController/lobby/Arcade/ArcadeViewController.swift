import UIKit
import RxSwift
import SharedBu

class ArcadeViewController: DisplayProduct {
    
    var barButtonItems: [UIBarButtonItem] = []
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tagsStackView: UIStackView!
    @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
    @IBOutlet private weak var scrollViewContentHeight: NSLayoutConstraint!
    private var viewModel = DI.resolve(ArcadeViewModel.self)!
    private var disposeBag = DisposeBag()
    lazy var gameDataSourceDelegate = { return ProductGameDataSourceDelegate(self) }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
        self.bind(position: .right, barButtonItems: .kto(.search), .kto(.favorite), .kto(.record))
        initUI()
        dataBinding()
    }
    
    private func initUI() {
        gamesCollectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    private func dataBinding() {
        viewModel.gameSource
            .catchError({ [weak self] (error) in
                self?.handleUnknownError(error)
                return Observable.just([])
            })
            .subscribe(onNext: { [weak self] (games) in
                self?.reloadGameData(games)
        }).disposed(by: disposeBag)
        viewModel.gameFilter.bind(onNext: { [weak self] (tags) in
            guard let `self` = self else { return }
            self.addBtnTags(stackView: self.tagsStackView, data: tags)
        }).disposed(by: disposeBag)
    }
    
    
    @objc override func pressGameTag(_ sender: UIButton) {
        viewModel.toggleFilter(gameTagId: sender.tag)
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
