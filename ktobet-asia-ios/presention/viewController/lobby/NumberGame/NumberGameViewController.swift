import UIKit
import RxSwift
import RxCocoa
import SharedBu
import SDWebImage
import TYCyclePagerView


class NumberGameViewController: DisplayProduct {
    @IBOutlet weak var blurImageBackgroundView: UIImageView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet weak var tagsStackView: UIStackView!
    @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
    @IBOutlet weak var dropDownView: UIView!
    @IBOutlet weak var dropDownTableView: UITableView!
    @IBOutlet weak var iconArrowImageView: UIImageView!
    @IBOutlet weak var dropDownTitleLabel: UILabel!
    @IBOutlet var gamesCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet var blurBackgroundViewHeight: NSLayoutConstraint!
    
    private var viewModel = DI.resolve(NumberGameViewModel.self)!
    private var disposeBag = DisposeBag()
    lazy var gameDataSourceDelegate = { return ProductGameDataSourceDelegate(self) }()
    private var viewDidRotate = BehaviorRelay<Bool>.init(value: false)
    lazy private var tagAll: NumberGameTag = {
        NumberGameTag(GameTag(type: TagAllID, name: Localize.string("common_all")), isSelected: false)
    }()
    lazy private var tagRecommand: NumberGameTag = {
        NumberGameTag(GameTag(type: TagRecommandID, name: Localize.string("common_recommend")), isSelected: false)
    }()
    lazy private var tagNew: NumberGameTag = {
        NumberGameTag(GameTag(type: TagNewID, name: Localize.string("common_new")), isSelected: false)
    }()
    var datas = [NumberGame]()
    var barButtonItems: [UIBarButtonItem] = []
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
    var dropDownItem: [(contentText: String, isSelected: Bool, sorting: GameSorting)] = [(Localize.string("product_hot_sorting"), true, .popular),
                                                                                         (Localize.string("product_name_sorting"), false, .gamename),
                                                                                         (Localize.string("product_release_sorting"), false, .releaseddate)]
    
    fileprivate func getPopularGames() {
        viewModel.popularGames.subscribe {[weak self] (numberGames) in
            guard let self = self,
                  let urlStr = numberGames.first?.thumbnail.url(),
                  let url = URL(string: urlStr) else { return }
            if self.datas.count == 0 && numberGames.count >= 3 {
                self.addBlurBackgoundImageView(url: url)
                self.pagerView.scrollToItem(at: 0, animate: false)
            }
            self.datas = numberGames
            if self.datas.count < 3 {
                self.blurBackgroundViewHeight.constant = 20
                self.pagerView.isHidden = true
            } else {
                self.pagerView.reloadData()
            }
        } onError: {[weak self] (error) in
            self?.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }
    
    fileprivate func getAllGames() {
        viewModel.allGames.subscribe {[weak self] (numberGames) in
            guard let self = self else { return }
            self.reloadGameData(numberGames)
        } onError: {[weak self] (error) in
            self?.handleUnknownError(error)
        }.disposed(by: disposeBag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
        self.bind(position: .right, barButtonItems: .kto(.search), .kto(.favorite), .kto(.record))
        scrollView.addSubview(pagerView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapDropDown))
        dropDownView.addGestureRecognizer(tapGesture)
        dropDownTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
        gamesCollectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        gamesCollectionView.registerCellFromNib(WebGameItemCell.className)
        
        getPopularGames()
        
        let data = [tagAll]
        addBtnTags(stackView: tagsStackView, data: data)
        Observable.combineLatest(viewDidRotate, viewModel.gameTagStates)
            .flatMap { (_, tags) -> Observable<[NumberGameTag]> in
            return Observable.just(tags)
        }.catchError({ [weak self] (error) -> Observable<[NumberGameTag]> in
            guard let `self` = self else { return Observable.just([])}
            return Observable.just([self.tagAll])
        }).subscribe(onNext: { [weak self] (tags: [NumberGameTag]) in
            guard let `self` = self else { return }
            var data = [self.tagAll]
            if tags.filter({ $0.isSelected }).count == 0 {
                self.tagAll.isSelected = true
            }
            data.append(contentsOf: tags)
            self.addBtnTags(stackView: self.tagsStackView, data: data)
        }).disposed(by: self.disposeBag)

        getAllGames()
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
    
    @objc private func didTapDropDown() {
        dropDownTableView.isHidden = !dropDownTableView.isHidden
        iconArrowImageView.image = dropDownTableView.isHidden ? UIImage(named: "iconAccordionArrowDown") : UIImage(named: "iconAccordionArrowUp")
    }
    
    fileprivate func setDropDownSort(index : Int) {
        let indexPath = IndexPath(row: index, section: 0)
        self.dropDownTitleLabel.text = dropDownItem[index].contentText
        self.dropDownItem = self.dropDownItem.map { (contentText: $0.contentText, isSelected: false, sorting: $0.sorting) }
        self.dropDownTableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.dropDownItem[index].isSelected = true
        self.dropDownTableView.reloadData()
    }
    
    @objc override func pressGameTag(_ sender: UIButton) {
        if sender.tag == TagAllID {
            tagAll.isSelected = true
            viewModel.setRecommendFilter(isRecommand: false)
            viewModel.setNewFilter(isNew: false)
        } else {
            tagAll.isSelected = false
        }
        
        if sender.tag == TagRecommandID {
            tagRecommand.isSelected.toggle()
            viewModel.setRecommendFilter(isRecommand: !sender.isSelected)
        }
        
        if sender.tag == TagNewID {
            viewModel.setNewFilter(isNew: !sender.isSelected)
        }
        
        viewModel.toggleFilter(gameTagId: sender.tag)

        if ((sender.tag == TagNewID && !sender.isSelected) ||
            self.viewModel.gameTags.contains(where: { $0.isSelected && $0.tagId == TagNewID })) &&
            self.viewModel.gameTags.contains(where: { !$0.isSelected && $0.tagId == TagRecommandID })
        {
            setDropDownSort(index: 2)
        } else {
            setDropDownSort(index: 0)
        }
        
        if (sender.tag == TagRecommandID && !sender.isSelected) {
            setDropDownSort(index: 0)
        }
    }
    
    private func addBlurBackgoundImageView(url: URL) {
        let blur = SDImageBlurTransformer.init(radius: 16)
        blurImageBackgroundView.sd_setImage(with: url, placeholderImage: nil, options: SDWebImageOptions.init(), context: [.imageTransformer : blur])
        
        let bottomGradient = CAGradientLayer()
        bottomGradient.startPoint = CGPoint(x: 0.5, y: 0.7)
        bottomGradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        bottomGradient.frame = blurImageBackgroundView.bounds
        let startColor = UIColor.clear.cgColor
        let endColor = UIColor.black_two.cgColor
        bottomGradient.colors = [startColor, endColor]
        blurImageBackgroundView.layer.insertSublayer(bottomGradient, at: 0)
        
        let topGradient = CAGradientLayer()
        topGradient.startPoint = CGPoint(x: 0.5, y: 0.3)
        topGradient.endPoint = CGPoint(x: 0.5, y: 0.0)
        topGradient.frame = blurImageBackgroundView.bounds
        let startColor1 = UIColor.clear.cgColor
        let endColor1 = UIColor.black_two.cgColor
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
        
        self.showToast(ToastPopUp(icon: icon!, text: text))
    }
    
    // MARK: KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            if let obj = object as? UICollectionView , obj == gamesCollectionView {
                gamesCollectionViewHeight.constant = gamesCollectionView.contentSize.height
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

extension NumberGameViewController: TYCyclePagerViewDelegate, TYCyclePagerViewDataSource {
    func numberOfItems(in pageView: TYCyclePagerView) -> Int {
        return self.datas.count
    }
    
    func pagerView(_ pagerView: TYCyclePagerView, cellForItemAt index: Int) -> UICollectionViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cellId", for: index) as! TYCyclePagerViewCell
        if let url = URL(string: datas[index].thumbnail.url()) {
            cell.imageView.sd_setImage(with: url, completed: nil)
            cell.label.text = datas[index].gameName
            cell.button.setImage(datas[index].isFavorite ? UIImage(named: "game-favorite-active") : UIImage(named: "game-favorite-activeinactive"), for: .normal)
            cell.toggleFavorite = {[weak self] in
                guard let self = self else { return }
                self.viewModel.toggleFavorite(game: self.datas[index]) {[weak self] (action) in
                    self?.showToast(action)
                } onError: {[weak self] (error) in
                    self?.handleUnknownError(error)
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
        let game = datas[index]
        let storyboard = UIStoryboard(name: "Product", bundle: nil)
        let navi = storyboard.instantiateViewController(withIdentifier: "GameNavigationViewController") as! UINavigationController
        if let gameVc = navi.viewControllers.first as? GameWebViewViewController {
            gameVc.gameId = game.gameId
            gameVc.gameName = game.gameName
            gameVc.viewModel = self.viewModel
            navi.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
            self.present(navi, animated: true, completion: nil)
        }
    }
}

extension NumberGameViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DropDownCell") as! DropDownTableViewCell
        cell.contentText.text = dropDownItem[indexPath.row].contentText
        cell.selectedImageView.isHidden = !dropDownItem[indexPath.row].isSelected
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dropDownItem = self.dropDownItem.map { (contentText: $0.contentText, isSelected: false, sorting: $0.sorting) }
        dropDownTitleLabel.text = dropDownItem[indexPath.row].contentText
        dropDownItem[indexPath.row].isSelected = true
        dropDownTableView.isHidden = true
        iconArrowImageView.image = UIImage(named: "iconAccordionArrowDown")
        viewModel.gameSorting.accept(dropDownItem[indexPath.row].sorting)
        dropDownTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        dropDownItem[indexPath.row].isSelected = false
        dropDownTableView.reloadData()
        
        return indexPath
    }
}

extension NumberGameViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        switch sender {
        case is RecordBarButtonItem:
            guard let numberGameSummaryViewController = UIStoryboard(name: "NumberGame", bundle: nil).instantiateViewController(withIdentifier: "NumberGameSummaryViewController") as? NumberGameSummaryViewController else { return }
            self.navigationController?.pushViewController(numberGameSummaryViewController, animated: true)
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
