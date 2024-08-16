import AlignedCollectionViewFlowLayout
import RxCocoa
import RxSwift
import sharedbu
import SideMenu
import SnapKit
import UIKit

class CasinoViewController: DisplayProduct {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var lobbyCollectionView: CasinoLobbyCollectionView!
    @IBOutlet var lobbyCollectionUpSpace: NSLayoutConstraint!
    @IBOutlet var lobbyCollectionHeight: NSLayoutConstraint!
    @IBOutlet var tagsStackView: GameTagStackView!
    @IBOutlet var gamesCollectionView: WebGameCollectionView!

    @IBOutlet private var scrollViewContentHeight: NSLayoutConstraint!

    private var lobbies: [CasinoDTO.Lobby] = []
    private var viewDidRotate = BehaviorRelay<Bool>(value: false)
    private var disposeBag = DisposeBag()
    private var lobbyHeight: CGFloat = 0
    private var tagsHeight: CGFloat = 0
    private var gamesHeight: CGFloat = 0

    private let titleLabelTopSpacing: CGFloat = 8
    private let titleLabelHeight: CGFloat = 32
    private let componentSpacing: CGFloat = 24
    private let gamesCollectionViewBottomSpacing: CGFloat = 96

    lazy var gameDataSourceDelegate = ProductGameDataSourceDelegate(self)

    var barButtonItems: [UIBarButtonItem] = []

    var viewModel = Injectable.resolveWrapper(CasinoViewModel.self)

    override func viewDidLoad() {
        super.viewDidLoad()

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
        gamesCollectionView
    }

    func setProductGameDataSourceDelegate() -> ProductGameDataSourceDelegate {
        gameDataSourceDelegate
    }

    func setViewModel() -> DisplayProductViewModel? {
        viewModel
    }

    override func setProductType() -> ProductType {
        .casino
    }
}

// MARK: - UI

extension CasinoViewController {
    private func setupUI() {
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)

        bind(
            position: .right,
            barButtonItems: .kto(.search), .kto(.favorite), .kto(.record)
        )

        lobbyCollectionView.registerCellFromNib(CasinoLobbyItemCell.className)

        lobbyCollectionView.dataSource = self
        lobbyCollectionView.delegate = self

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(scrollView.snp.top).offset(titleLabelTopSpacing)
            make.left.right.equalToSuperview().inset(30)
            make.height.equalTo(titleLabelHeight)
        }

        lobbyCollectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(componentSpacing)
            make.left.right.equalToSuperview().inset(25)
            make.height.equalTo(100)
        }

        tagsStackView.snp.makeConstraints { make in
            make.top.equalTo(lobbyCollectionView.snp.bottom).offset(componentSpacing)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(50)
        }

        gamesCollectionView.snp.makeConstraints { make in
            make.top.equalTo(tagsStackView.snp.bottom).offset(componentSpacing)
            make.left.right.equalToSuperview().inset(24)
            make.height.equalTo(300)
            make.bottom.equalTo(scrollView.snp.bottom).offset(-gamesCollectionViewBottomSpacing)
        }
    }

    private func binding() {
        viewModel.errors()
            .subscribe(onNext: { [weak self] in
                if $0.isMaintenance() {
                    NavigationManagement.sharedInstance
                        .goTo(
                            productType: .casino,
                            isMaintenance: true
                        )
                } else {
                    self?.handleErrors($0)
                }
            })
            .disposed(by: disposeBag)

        bindWebGameResult(with: viewModel)

        Observable
            .combineLatest(
                viewDidRotate,
                viewModel.getLobbies().asObservable()
            )
            .do(onNext: { [weak self] didRoTate, _ in
                if didRoTate { self?.scrollViewContentHeight.constant = 0 }
            }, onError: { [weak self] _ in
                self?.lobbyCollectionUpSpace.constant = 0
                self?.lobbyCollectionHeight.constant = 0
            })
            .map { $1 }
            .subscribe(on: MainScheduler.instance)
            .subscribe(onNext: { [unowned self] lobbies in
                self.lobbies = appendPlaceholdersIfNeeded(lobbies)
                lobbyCollectionView.reloadData()
            })
            .disposed(by: disposeBag)

        viewModel.searchedCasinoByTag
            .subscribe(onNext: { [weak self] games in
                self?.reloadGameData(games)
            })
            .disposed(by: disposeBag)

        bindPlaceholder(.casino, with: viewModel)

        Observable
            .combineLatest(
                viewDidRotate,
                viewModel.tagStates
            )
            .subscribe(onNext: { [unowned self] _, data in
                self.tagsStackView.initialize(
                    data: data,
                    allTagClick: { self.viewModel.selectAll() },
                    customClick: { self.viewModel.toggleTag($0) }
                )

                tagsHeight = tagsStackView.calculateHeight()
                self.tagsStackView.snp.updateConstraints { make in
                    make.height.equalTo(tagsHeight)
                }

                updateScrollViewContentHeight()
            })
            .disposed(by: disposeBag)

        Observable
            .combineLatest(
                gamesCollectionView.rx.observe(\.contentSize).compactMap { $0 },
                lobbyCollectionView.rx.observe(\.contentSize).compactMap { $0 }
            )
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [unowned self] (gameSize: CGSize, lobbySize: CGSize) in
                self.lobbyCollectionView.snp.updateConstraints { make in
                    make.height.equalTo(lobbySize.height)
                }
                self.gamesCollectionView.snp.updateConstraints { make in
                    make.height.equalTo(gameSize.height)
                }
                self.lobbyHeight = lobbySize.height
                self.gamesHeight = gameSize.height
                updateScrollViewContentHeight()
            })
            .disposed(by: disposeBag)
    }

    private func updateScrollViewContentHeight() {
        let componentTotalHeight = titleLabelHeight + lobbyHeight +
            tagsHeight + gamesHeight
        let componentTotalSpacing = titleLabelTopSpacing + gamesCollectionViewBottomSpacing + componentSpacing * 3
        let totalContentHeight = componentTotalHeight + componentTotalSpacing

        scrollViewContentHeight.constant = totalContentHeight
        scrollView.contentSize = CGSize(width: scrollView.frame.width, height: totalContentHeight)
    }

    private func appendPlaceholdersIfNeeded(_ lobbies: [CasinoDTO.Lobby]) -> [CasinoDTO.Lobby] {
        let remainder = lobbies.count % 3
        guard remainder > 0 else { return lobbies }

        let placeholdersNeeded = 3 - remainder
        let placeholders = Array(repeating: CasinoDTO.Lobby.placeHolder, count: placeholdersNeeded)
        return lobbies + placeholders
    }
}

// MARK: - BarButtonItemable

extension CasinoViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        switch sender {
        case is RecordBarButtonItem:
            guard
                let casinoSummaryViewController = UIStoryboard(name: "Casino", bundle: nil)
                .instantiateViewController(
                    withIdentifier: "CasinoSummaryViewController"
                ) as? CasinoSummaryViewController
            else { return }
            navigationController?.pushViewController(casinoSummaryViewController, animated: true)
        case is FavoriteBarButtonItem:
            guard
                let favoriteViewController = UIStoryboard(name: "Product", bundle: nil)
                .instantiateViewController(withIdentifier: "FavoriteViewController") as? FavoriteViewController
            else { return }
            favoriteViewController.viewModel = viewModel
            navigationController?.pushViewController(favoriteViewController, animated: true)
        case is SearchButtonItem:
            guard
                let searchViewController = UIStoryboard(name: "Product", bundle: nil)
                .instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController
            else { return }
            searchViewController.viewModel = viewModel
            navigationController?.pushViewController(searchViewController, animated: true)
        default: break
        }
    }
}

// MARK: - UICollectionView Component

extension CasinoViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        lobbies.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        collectionView.dequeueReusableCell(cellType: CasinoLobbyItemCell.self, indexPath: indexPath)
            .configure(lobbies[indexPath.row])
    }
}

extension CasinoViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let data = lobbies[indexPath.row]
        guard
            let casinoLobbyViewController = UIStoryboard(name: "Casino", bundle: nil)
            .instantiateViewController(withIdentifier: "CasinoLobbyViewController") as? CasinoLobbyViewController,
            data.isMaintenance == false else { return }
        casinoLobbyViewController.viewModel = viewModel
        casinoLobbyViewController.lobby = data
        navigationController?.pushViewController(casinoLobbyViewController, animated: true)
    }
}

extension CasinoViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        size(for: indexPath)
    }

    private func size(for indexPath: IndexPath) -> CGSize {
        let cell = Bundle.main.loadNibNamed("CasinoLobbyItemCell", owner: self, options: nil)?
            .first as! CasinoLobbyItemCell
        let data = lobbies[indexPath.item]
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
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        collectionViewLayout.collectionViewContentSize
    }
}
