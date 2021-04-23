import UIKit
import RxSwift
import RxCocoa
import share_bu
import AlignedCollectionViewFlowLayout

let TagAllID: Int32 = -1
class CasinoViewController: UIViewController {

    var barButtonItems: [UIBarButtonItem] = []
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lobbyCollectionView: CasinoLobbyCollectionView!
    @IBOutlet weak var lobbyCollectionUpSpace: NSLayoutConstraint!
    @IBOutlet weak var lobbyCollectionHeight: NSLayoutConstraint!
    @IBOutlet weak var tagsStackView: UIStackView!
    @IBOutlet weak var gamesCollectionView: CasinoGameCollectionView!
    private var lobbies: [CasinoLobby] = []
    lazy var gameDataSourceDelegate = { return CasinoGameDataSourceDelegate(self) }()
    private var gameData: [CasinoGame] = [] {
        didSet {
            self.gameDataSourceDelegate.setGames(gameData)
            self.gamesCollectionView.reloadData()
        }
    }
    @IBOutlet private weak var scrollViewContentHeight: NSLayoutConstraint!
    lazy private var tagAll: CasinoTag = {
        CasinoTag(CasinoGameTag.GameType(id: TagAllID, name: Localize.string("common_all")), isSeleced: true)
    }()
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
    
    fileprivate func initUI() {
        gamesCollectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        gamesCollectionView.registerCellFromNib(CasinoGameItemCell.className)
        let data = [tagAll]
        addBtnTags(stackView: tagsStackView, data: data)
        lobbyCollectionView.dataSource = self
        lobbyCollectionView.delegate = self
    }
    
    fileprivate func dataBinding() {
        gamesCollectionView.dataSource = gameDataSourceDelegate
        gamesCollectionView.delegate = gameDataSourceDelegate
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
                self?.handleUnknownError(error)
                return Observable.just([])
            })
            .subscribe(onNext: { [weak self] (games) in
            self?.gameData = games
        }).disposed(by: disposeBag)
        
        viewModel.casinoGameTagStates
            .catchError({ [weak self] (error) -> Observable<[CasinoTag]> in
                guard let `self` = self else { return Observable.just([])}
                return Observable.just([self.tagAll])
            })
            .subscribe(onNext: { [weak self] (tags: [CasinoTag]) in
            guard let `self` = self else { return }
            var data = [self.tagAll]
            if tags.filter({ $0.isSeleced }).count == 0 {
                self.tagAll.isSeleced = true
            }
            data.append(contentsOf: tags)
            self.addBtnTags(stackView: self.tagsStackView, data: data)
        }).disposed(by: self.disposeBag)
    }
    
    private func addBtnTags(stackView: UIStackView, data: [CasinoTag]) {
        stackView.removeAllArrangedSubviews()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 8
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        
        var btns: [[UIButton]] = [[]]
        var childRow = createOneChildView(stackView)
        var rowInex = 0
        stackView.addArrangedSubview(childRow)
        for i in 0..<data.count {
            let dx = btns[rowInex].reduce(0) { (total, btn) -> CGFloat in
                return total + btn.frame.size.width + 8
            }
            let frame = CGRect(x: dx, y: 0, width: 180, height: 40 )
            let button = UIButton(frame: frame)
            button.setTitle("\(data[i].name)", for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 18, bottom: 8, right: 18)
            button.sizeToFit()
            button.layer.cornerRadius = 20
            button.layer.masksToBounds = true
            if data[i].isSeleced {
                button.applyGradient(colors: [UIColor(rgb: 0xf74d25).cgColor, UIColor(rgb: 0xf20000).cgColor])
            } else {
                button.applyGradient(colors: [UIColor(rgb: 0x32383e).cgColor, UIColor(rgb: 0x17191c).cgColor])
            }
            if dx+button.frame.size.width > tagsStackView.frame.size.width {
                childRow = createOneChildView(stackView)
                rowInex += 1
                btns.append([])
                stackView.addArrangedSubview(childRow)
                button.frame.origin.x = 0
            }
            button.tag = Int(data[i].id)
            button.isSelected = data[i].isSeleced
            button.addTarget(self, action: #selector(pressGameTag(_:)), for: .touchUpInside)
            childRow.addSubview(button)
            btns[rowInex].append(button)
        }
    }
    
    private func createOneChildView(_ parentView: UIStackView) -> UIView {
        let childRow = UIView(frame: .zero)
        childRow.heightAnchor.constraint(equalToConstant: 40.0).isActive = true
        childRow.widthAnchor.constraint(equalToConstant: parentView.frame.size.width).isActive = true
        return childRow
    }
    
    @objc private func pressGameTag(_ sender: UIButton) {
        if sender.tag == TagAllID {
            tagAll.isSeleced = true
        } else {
            tagAll.isSeleced = false
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
    
}

extension CasinoViewController: CasinoFavoriteProtocol {
    func toggleFavorite(_ game: CasinoGame, onCompleted: @escaping (FavoriteAction)->(), onError: @escaping (Error)->()) {
        viewModel.toggleFavorite(casinoGame: game, onCompleted: onCompleted, onError: onError)
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
            guard let casinoFavoriteViewController = UIStoryboard(name: "Casino", bundle: nil).instantiateViewController(withIdentifier: "CasinoFavoriteViewController") as? CasinoFavoriteViewController else { return }
            casinoFavoriteViewController.viewModel = self.viewModel
            self.navigationController?.pushViewController(casinoFavoriteViewController, animated: true)
            break
        case is SearchButtonItem:
            guard let casinoSearchViewController = UIStoryboard(name: "Casino", bundle: nil).instantiateViewController(withIdentifier: "CasinoSearchViewController") as? CasinoSearchViewController else { return }
            casinoSearchViewController.viewModel = self.viewModel
            self.navigationController?.pushViewController(casinoSearchViewController, animated: true)
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
        blurView.layer.cornerRadius = self.bounds.width / 2
        blurView.layer.masksToBounds = true
        return self
    }
}
