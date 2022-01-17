import UIKit
import RxSwift
import SharedBu

enum MoreGame: Int {
    case RecentPlay     = 666
    case SlotNew
    case Jackpot
    
    func localizeString() -> String {
        switch self {
        case .RecentPlay:
            return Localize.string("product_slot_recent_play")
        case .SlotNew:
            return Localize.string("product_slot_new")
        case .Jackpot:
            return Localize.string("product_slot_jackpot")
        }
    }
}
class SlotSeeMoreViewController: DisplayProduct {
    
    static let segueIdentifier = "toSlotSeeMore"
    var type: MoreGame = .RecentPlay
    var games: [SlotGame] = []
    var viewModel: SlotViewModel?
    private var disposeBag = DisposeBag()
    
    @IBOutlet weak var scrollViewContentHeight: NSLayoutConstraint!
    @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
    lazy var gameDataSourceDelegate = { return ProductGameDataSourceDelegate(self) }()
    
    var barButtonItems: [UIBarButtonItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, title: type.localizeString())
        initUI()
        dataBinding()
    }
    
    private func initUI() {
        self.bind(position: .right, barButtonItems: .kto(.search))
        gamesCollectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        gamesCollectionView.registerCellFromNib(WebGameItemCell.className)
    }
    
    private func dataSource() -> Observable<[SlotGame]>? {
        var dataSource: Observable<[SlotGame]>?
        switch type {
        case .RecentPlay:
            dataSource = viewModel?.recentGames
        case .SlotNew:
            dataSource = viewModel?.newGames
        case .Jackpot:
            dataSource = viewModel?.jackpotGames
        }
        return dataSource
    }
    
    private func dataBinding() {
        dataSource()?.catchError({ [weak self] (error) -> Observable<[SlotGame]> in
            self?.handleErrors(error)
            return Observable.just([])
        }).subscribe(onNext: { [weak self] (games) in
            self?.reloadGameData(games)
        }).disposed(by: disposeBag)
    }
    
    // MARK: KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize", let newvalue = change?[.newKey] {
            if let obj = object as? UICollectionView , obj == gamesCollectionView {
                let space: CGFloat = 30
                scrollViewContentHeight.constant = (newvalue as! CGSize).height + space
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

extension SlotSeeMoreViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        guard let searchViewController = UIStoryboard(name: "Product", bundle: nil).instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController else { return }
        searchViewController.viewModel = self.viewModel
        self.navigationController?.pushViewController(searchViewController, animated: true)
    }
}
