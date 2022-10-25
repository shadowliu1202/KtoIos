import UIKit
import RxSwift
import RxCocoa
import SharedBu

class FavoriteViewController: DisplayProduct {

    @IBOutlet weak var scrollViewContentHeight: NSLayoutConstraint!
    @IBOutlet weak var emptyViewAddButton: UIButton!
    @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
    lazy var gameDataSourceDelegate = { return ProductGameDataSourceDelegate(self) }()
    private var gameData: [WebGameWithDuplicatable] = [] {
        didSet {
            self.switchContent(gameData)
            self.reloadGameData(gameData)
        }
    }
    @IBOutlet weak var emptyView: UIView!
    var viewModel: DisplayProductViewModel?
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, title: Localize.string("product_favorite"))
        initUI()
        dataBinding()
    }
    
    private func initUI() {
        gamesCollectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    private func dataBinding() {
        viewModel?.getFavorites()
        emptyViewAddButton.rx.touchUpInside.bind { _ in
            NavigationManagement.sharedInstance.popViewController()
        }.disposed(by: disposeBag)
        viewModel?.favoriteProducts()
            .catchError({ [weak self] (error) -> Observable<[WebGameWithDuplicatable]> in
                switch error {
                case KTOError.EmptyData:
                    self?.switchContent()
                    break
                default:
                    self?.handleErrors(error)
                }
                return Observable.just([])
            }).subscribe(onNext: { [weak self] (games) in
                self?.gameData = games
            }).disposed(by: self.disposeBag)
    }
    
    private func switchContent(_ games: [WebGameWithProperties]? = nil) {
        if let items = games, items.count > 0 {
            self.gamesCollectionView.isHidden = false
            self.emptyView.isHidden = true
        } else {
            self.gamesCollectionView.isHidden = true
            self.emptyView.isHidden = false
        }
    }
    
    // MARK: KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize", let newvalue = change?[.newKey] {
            if let obj = object as? UICollectionView , obj == gamesCollectionView {
                let space: CGFloat = 30
                let bottomPadding: CGFloat = 96
                scrollViewContentHeight.constant = (newvalue as! CGSize).height + space + bottomPadding
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
        viewModel!.getGameProductType()
    }
}
