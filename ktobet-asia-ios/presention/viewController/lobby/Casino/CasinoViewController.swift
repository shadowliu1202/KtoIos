import UIKit
import RxSwift
import RxCocoa
import SharedBu
import AlignedCollectionViewFlowLayout
import SideMenu

class CasinoViewController: DisplayProduct {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lobbyCollectionView: CasinoLobbyCollectionView!
    @IBOutlet weak var lobbyCollectionUpSpace: NSLayoutConstraint!
    @IBOutlet weak var lobbyCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var tagsStackView: GameTagStackView!
    @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
    
    @IBOutlet private weak var scrollViewContentHeight: NSLayoutConstraint!
    
    @Injected private var loading: Loading
    
    private var lobbies: [CasinoLobby] = []
    private var viewDidRotate = BehaviorRelay<Bool>.init(value: false)
    private var disposeBag = DisposeBag()

    lazy var gameDataSourceDelegate = { return ProductGameDataSourceDelegate(self) }()
    
    var barButtonItems: [UIBarButtonItem] = []
    
    var viewModel = Injectable.resolveWrapper(CasinoViewModel.self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Logger.shared.info("\(type(of: self)) viewDidLoad.")
        
        setupUI()
        binding()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil, completion: { [weak self] _ in
            self?.viewDidRotate.accept(true)
        })
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
        .casino
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

// MARK: - UI

private extension CasinoViewController {
    
    func setupUI() {
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
        
        bind(
            position: .right,
            barButtonItems: .kto(.search), .kto(.favorite), .kto(.record)
        )
        
        lobbyCollectionView.registerCellFromNib(CasinoLobbyItemCell.className)
        
        lobbyCollectionView.dataSource = self
        lobbyCollectionView.delegate = self
    }
    
    func binding() {
        viewModel.errors()
            .subscribe(onNext: { [weak self] in
            if $0.isMaintenance() {
                NavigationManagement.sharedInstance
                    .goTo(
                        productType: .casino,
                        isMaintenance: true
                    )
            }
            else {
                self?.handleErrors($0)
            }
        })
        .disposed(by: disposeBag)
        
        bindWebGameResult(with: viewModel)
        
        viewModel.activityIndicator
            .bind(to: loading)
            .disposed(by: disposeBag)
        
        Observable
            .combineLatest(
                viewDidRotate,
                viewModel.lobby().asObservable()
            )
            .do(onNext: { [weak self] (didRoTate , _) in
                if didRoTate { self?.scrollViewContentHeight.constant = 0 }
            }, onError: { [weak self] _ in
                self?.lobbyCollectionUpSpace.constant = 0
                self?.lobbyCollectionHeight.constant = 0
            })
            .map { $1 }
            .catchAndReturn([])
            .subscribe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (lobbies) in
                guard let `self` = self else { return }
                self.lobbies = lobbies
                self.lobbyCollectionView.reloadData()
            })
            .disposed(by: disposeBag)
                
        viewModel.searchedCasinoByTag
            .subscribe(onNext: { [weak self] (games) in
                self?.reloadGameData(games)
            })
            .disposed(by: disposeBag)
                
        Observable
            .combineLatest(
                viewDidRotate,
                viewModel.tagStates
            )
            .subscribe(onNext: { [unowned self] (_, data) in
                self.tagsStackView.initialize(
                    data: data,
                    allTagClick: { self.viewModel.selectAll() },
                    customClick: { self.viewModel.toggleTag($0) }
                )
            })
            .disposed(by: disposeBag)
        
        Observable
            .combineLatest(
                gamesCollectionView.rx.observe(\.contentSize),
                lobbyCollectionView.rx.observe(\.contentSize)
            )
            .asDriverLogError()
            .map { [unowned self] (game, lobby) -> CGFloat in
                let aboveHeight = self.titleLabel.frame.size.height + self.tagsStackView.frame.size.height
                let space: CGFloat = 8 + 34 + 24 * 2
                return game.height + lobby.height + aboveHeight + space
            }
            .drive(onNext: { [unowned self] in
                self.scrollViewContentHeight.constant = $0
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - BarButtonItemable

extension CasinoViewController: BarButtonItemable {
    
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        switch sender {
        case is RecordBarButtonItem:
            guard let casinoSummaryViewController = UIStoryboard(name: "Casino", bundle: nil).instantiateViewController(withIdentifier: "CasinoSummaryViewController") as? CasinoSummaryViewController else { return }
            self.navigationController?.pushViewController(casinoSummaryViewController, animated: true)
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

// MARK: - UICollectionView Component

extension CasinoViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return lobbies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(cellType: CasinoLobbyItemCell.self, indexPath: indexPath).configure(lobbies[indexPath.row])
    }
}

extension CasinoViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let data = lobbies[indexPath.row]
        guard let casinoLobbyViewController = UIStoryboard(name: "Casino", bundle: nil).instantiateViewController(withIdentifier: "CasinoLobbyViewController") as? CasinoLobbyViewController, data.isMaintenance == false else { return }
        casinoLobbyViewController.viewModel = self.viewModel
        casinoLobbyViewController.lobby = data
        self.navigationController?.pushViewController(casinoLobbyViewController, animated: true)
    }
}

extension CasinoViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return size(for: indexPath)
    }
    
    private func size(for indexPath: IndexPath) -> CGSize {
        let cell = Bundle.main.loadNibNamed("CasinoLobbyItemCell", owner: self, options: nil)?.first as! CasinoLobbyItemCell
        let data = self.lobbies[indexPath.item]
        cell.configure(data)
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        let size = cell.contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        return size
    }
}

class CasinoLobbyCollectionView: UICollectionView {
    override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
    }
    override var intrinsicContentSize: CGSize {
        return self.collectionViewLayout.collectionViewContentSize
    }
}
