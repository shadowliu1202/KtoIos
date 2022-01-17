import UIKit
import RxSwift
import RxCocoa
import SharedBu
import AlignedCollectionViewFlowLayout

let TagAllID: Int32 = -1
let TagRecommandID: Int32 = -2
let TagNewID: Int32 = -3
class CasinoViewController: DisplayProduct {

    var barButtonItems: [UIBarButtonItem] = []
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lobbyCollectionView: CasinoLobbyCollectionView!
    @IBOutlet weak var lobbyCollectionUpSpace: NSLayoutConstraint!
    @IBOutlet weak var lobbyCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var tagsStackView: UIStackView!
    @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
    private var lobbies: [CasinoLobby] = []
    lazy var gameDataSourceDelegate = { return ProductGameDataSourceDelegate(self) }()
    @IBOutlet private weak var scrollViewContentHeight: NSLayoutConstraint!
    lazy private var tagAll: CasinoTag = {
        CasinoTag(CasinoGameTag.GameType(id: TagAllID, name: Localize.string("common_all")), isSeleced: false)
    }()
    private var viewDidRotate = BehaviorRelay<Bool>.init(value: false)
    private var viewModel = DI.resolve(CasinoViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
        self.bind(position: .right, barButtonItems: .kto(.search), .kto(.favorite), .kto(.record))
        initUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        disposeBag = DisposeBag()
        dataBinding()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil, completion: { [weak self] _ in
            self?.viewDidRotate.accept(true)
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.disposeBag = DisposeBag()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    fileprivate func initUI() {
        gamesCollectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        let data = [tagAll]
        addBtnTags(stackView: tagsStackView, data: data)
        lobbyCollectionView.dataSource = self
        lobbyCollectionView.delegate = self
    }
    
    fileprivate func dataBinding() {
        viewModel.lobby()
            .catchError({ [weak self] (error) -> Single<[CasinoLobby]> in
                self?.lobbyCollectionUpSpace.constant = 0
                self?.lobbyCollectionHeight.constant = 0
                return Single.just([])
            }).subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] (lobbies) in
                guard let `self` = self else { return }
                self.lobbies = lobbies
                self.lobbyCollectionView.reloadData()
            }).disposed(by: self.disposeBag)
        
        viewModel.searchedCasinoByTag
            .catchError({ [weak self] (error) -> Observable<[CasinoGame]> in
                self?.handleErrors(error)
                return Observable.just([])
            })
            .subscribe(onNext: { [weak self] (games) in
                self?.reloadGameData(games)
        }).disposed(by: disposeBag)
        
        Observable.combineLatest(viewDidRotate, viewModel.casinoGameTagStates)
            .flatMap { (_, tags) -> Observable<[CasinoTag]> in
            return Observable.just(tags)
        }.catchError({ [weak self] (error) -> Observable<[CasinoTag]> in
            guard let `self` = self else { return Observable.just([])}
            return Observable.just([self.tagAll])
        }).subscribe(onNext: { [weak self] (tags: [CasinoTag]) in
            guard let `self` = self else { return }
            var data = [self.tagAll]
            if tags.filter({ $0.isSelected }).count == 0 {
                self.tagAll.isSelected = true
            }
            data.append(contentsOf: tags)
            self.addBtnTags(stackView: self.tagsStackView, data: data)
        }).disposed(by: self.disposeBag)
    }
    
    @objc override func pressGameTag(_ sender: UIButton) {
        if sender.tag == TagAllID {
            tagAll.isSelected = true
        } else {
            tagAll.isSelected = false
        }
        viewModel.toggleFilter(gameTagId: sender.tag)
    }
    
    // MARK: KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize", let newvalue = change?[.newKey] {
            if let obj = object as? UICollectionView , obj == gamesCollectionView {
                let aboveHeight = titleLabel.frame.size.height + tagsStackView.frame.size.height + lobbyCollectionView.frame.size.height
                let space: CGFloat = 8 + 30 + 20 * 3
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

class CasinoLobbyCollectionView: UICollectionView {
    override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
    }
    override var intrinsicContentSize: CGSize {
        return self.collectionViewLayout.collectionViewContentSize
    }
}

class CasinoLobbyItemCell: UICollectionViewCell {
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var maintainIcon: UIImageView!
    @IBOutlet private weak var labTitle : UILabel!
    @IBOutlet private weak var blurView: UIView!
    @IBOutlet weak var imgWidth: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        mainView.translatesAutoresizingMaskIntoConstraints = false
        let width = floor( (UIScreen.main.bounds.size.width - 24 * 2 - 14 * 2) / 3 )
        self.mainView.constrain([.equal(\.widthAnchor, length: width)])
        imgWidth.constant = width - 4 * 2
    }
    
    func configure(_ data : CasinoLobby) -> Self {
        labTitle.text = data.name
        imgIcon.image = data.lobby.img
        maintainIcon.image = UIImage(named: "game-maintainance")
        blurView.isHidden = !data.isMaintenance
        self.isUserInteractionEnabled = !data.isMaintenance
        blurView.layer.cornerRadius = self.bounds.width / 2
        blurView.layer.masksToBounds = true
        return self
    }
}
