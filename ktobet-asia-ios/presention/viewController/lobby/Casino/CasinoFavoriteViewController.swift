import UIKit
import RxSwift
import RxCocoa
import share_bu

class CasinoFavoriteViewController: UIViewController {

    @IBOutlet weak var scrollViewContentHeight: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emptyViewAddButton: UIButton!
    @IBOutlet weak var gamesCollectionView: CasinoGameCollectionView!
    lazy var gameDataSourceDelegate = { return CasinoGameDataSourceDelegate(self) }()
    private var gameData: [CasinoGame] = [] {
        didSet {
            self.switchContent(gameData)
            self.gameDataSourceDelegate.setGames(gameData)
            self.gamesCollectionView.reloadData()
        }
    }
    @IBOutlet weak var emptyView: UIView!
    var viewModel: CasinoViewModel!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        initUI()
        dataBinding()
    }
    
    private func initUI() {
        gamesCollectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        gamesCollectionView.registerCellFromNib(CasinoGameItemCell.className)
    }
    
    private func dataBinding() {
        viewModel.getFavorites()
        emptyViewAddButton.rx.touchUpInside.bind { _ in
            NavigationManagement.sharedInstance.popViewController()
        }.disposed(by: disposeBag)
        gamesCollectionView.dataSource = gameDataSourceDelegate
        gamesCollectionView.delegate = gameDataSourceDelegate
        viewModel.favorites
            .catchError({ [weak self] (error) -> Observable<[CasinoGame]> in
                self?.switchContent()
                self?.handleUnknownError(error)
                return Observable.just([])
            }).subscribe(onNext: { [weak self] (games) in
                self?.gameData = games
            }).disposed(by: self.disposeBag)
    }
    
    private func switchContent(_ games: [CasinoGame]? = nil) {
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
                let aboveHeight = titleLabel.frame.size.height
                let space: CGFloat = 20
                scrollViewContentHeight.constant = (newvalue as! CGSize).height + aboveHeight + space
            }
        }
    }
    
}

extension CasinoFavoriteViewController: CasinoFavoriteProtocol {
    func toggleFavorite(_ game: CasinoGame, onCompleted: @escaping (FavoriteAction)->(), onError: @escaping (Error)->()) {
        viewModel.toggleFavorite(casinoGame: game, onCompleted: onCompleted, onError: onError)
    }
}
