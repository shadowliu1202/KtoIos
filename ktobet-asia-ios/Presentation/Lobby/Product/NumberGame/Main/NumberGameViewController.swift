import RxCocoa
import RxSwift
import SDWebImage
import sharedbu
import TYCyclePagerView
import UIKit

class NumberGameViewController: DisplayProduct {
  @IBOutlet weak var blurImageBackgroundView: UIImageView!
  @IBOutlet var scrollView: UIScrollView!
  @IBOutlet weak var tagsStackView: GameTagStackView!
  @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
  @IBOutlet weak var dropDownView: DropdownSelector!
  @IBOutlet var gamesCollectionViewHeight: NSLayoutConstraint!
  @IBOutlet var blurBackgroundViewHeight: NSLayoutConstraint!

  private lazy var viewModel = Injectable.resolve(NumberGameViewModel.self)!
  private var disposeBag = DisposeBag()

  private var viewDidRotate = BehaviorRelay<Bool>.init(value: false)

  lazy var gameDataSourceDelegate = ProductGameDataSourceDelegate(self)
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

  private var dropDownItem: [DropdownItem] =
    [
      .init(contentText: Localize.string("product_hot_sorting"), sorting: .popular),
      .init(contentText: Localize.string("product_name_sorting"), sorting: .gamename),
      .init(contentText: Localize.string("product_release_sorting"), sorting: .releaseddate)
    ]

  fileprivate func getPopularGames() {
    viewModel.popularGames.subscribe { [weak self] numberGames in
      guard
        let self,
        let urlStr = numberGames.first?.thumbnail.url(),
        let url = URL(string: urlStr)
      else {
        self?.blurBackgroundViewHeight.constant = 20
        self?.pagerView.isHidden = true
        return
      }

      if self.datas.count == 0, numberGames.count >= 3 {
        self.addBlurBackgoundImageView(url: url)
        self.pagerView.scrollToItem(at: 0, animate: false)
      }
      self.datas = numberGames
      if self.datas.count < 3 {
        self.blurBackgroundViewHeight.constant = 20
        self.pagerView.isHidden = true
      }
      else {
        self.pagerView.reloadData()
      }
    } onError: { [weak self] error in
      self?.handleErrors(error)
    }.disposed(by: disposeBag)
  }

  fileprivate func getAllGames() {
    viewModel.allGames.subscribe { [weak self] numberGames in
      guard let self else { return }
      self.reloadGameData(numberGames)
    } onError: { [weak self] error in
      self?.handleErrors(error)
    }.disposed(by: disposeBag)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    Logger.shared.info("\(type(of: self)) viewDidLoad.")
    NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
    self.bind(position: .right, barButtonItems: .kto(.search), .kto(.favorite), .kto(.record))
    scrollView.addSubview(pagerView)
    dropDownView.setItems(dropDownItem)
    dropDownView.setSelectedItem(dropDownItem.first)
    gamesCollectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    gamesCollectionView.registerCellFromNib(WebGameItemCell.className)

    getPopularGames()
    getAllGames()

    dataBinding()
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

  func dataBinding() {
    bindWebGameResult(with: viewModel)

    viewModel.errors().subscribe(onNext: { [weak self] in
      if $0.isMaintenance() {
        NavigationManagement.sharedInstance.goTo(productType: .numbergame, isMaintenance: true)
      }
      else {
        self?.handleErrors($0)
      }
    }).disposed(by: disposeBag)

    Observable.combineLatest(viewDidRotate, viewModel.tagStates)
      .flatMap { Observable.just($1) }
      .subscribe(onNext: { [unowned self] data in
        self.tagsStackView.initialize(
          recommend: data.0,
          new: data.1,
          data: data.2,
          allTagClick: { self.viewModel.selectAll() },
          recommendClick: { self.viewModel.toggleRecommend() },
          newClick: { self.viewModel.toggleNew() },
          customClick: { self.viewModel.toggleTag($0) })
      }).disposed(by: self.disposeBag)

    dropDownView.selectedItemObservable
      .subscribe(onNext: { [weak self] in
        guard let self, let sorting = ($0 as? DropdownItem)?.sorting else { return }
        self.viewModel.gameSorting.accept(sorting)
      })
      .disposed(by: disposeBag)

    bindPlaceholder(.numberGame, with: viewModel)
  }

  private func addBlurBackgoundImageView(url: URL) {
    let blur = SDImageBlurTransformer(radius: 16)
    blurImageBackgroundView.sd_setImage(url: url, context: [.imageTransformer: blur])

    let bottomGradient = CAGradientLayer()
    bottomGradient.startPoint = CGPoint(x: 0.5, y: 0.7)
    bottomGradient.endPoint = CGPoint(x: 0.5, y: 1.0)
    bottomGradient.frame = blurImageBackgroundView.bounds
    let startColor = UIColor.clear.cgColor
    let endColor = UIColor.greyScaleDefault.cgColor
    bottomGradient.colors = [startColor, endColor]
    blurImageBackgroundView.layer.insertSublayer(bottomGradient, at: 0)

    let topGradient = CAGradientLayer()
    topGradient.startPoint = CGPoint(x: 0.5, y: 0.3)
    topGradient.endPoint = CGPoint(x: 0.5, y: 0.0)
    topGradient.frame = blurImageBackgroundView.bounds
    let startColor1 = UIColor.clear.cgColor
    let endColor1 = UIColor.greyScaleDefault.cgColor
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

    self.showToastOnCenter(ToastPopUp(icon: icon!, text: text))
  }

  // MARK: KVO
  override func observeValue(
    forKeyPath keyPath: String?,
    of object: Any?,
    change _: [NSKeyValueChangeKey: Any]?,
    context _: UnsafeMutableRawPointer?)
  {
    if keyPath == "contentSize" {
      if let obj = object as? UICollectionView, obj == gamesCollectionView {
        gamesCollectionViewHeight.constant = gamesCollectionView.contentSize.height
      }
    }
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
    .numbergame
  }
}

extension NumberGameViewController: TYCyclePagerViewDelegate, TYCyclePagerViewDataSource {
  func numberOfItems(in _: TYCyclePagerView) -> Int {
    self.datas.count
  }

  func pagerView(_ pagerView: TYCyclePagerView, cellForItemAt index: Int) -> UICollectionViewCell {
    let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cellId", for: index) as! TYCyclePagerViewCell
    if let url = URL(string: datas[index].thumbnail.url()) {
      cell.imageView.sd_setImage(url: url, placeholderImage: nil)
      cell.label.text = datas[index].gameName
      cell.button.setImage(
        datas[index].isFavorite ? UIImage(named: "game-favorite-active") : UIImage(named: "game-favorite-activeinactive"),
        for: .normal)
      cell.toggleFavorite = { [weak self] in
        guard let self else { return }
        self.viewModel.toggleFavorite(game: self.datas[index]) { [weak self] action in
          self?.showToast(action)
        } onError: { [weak self] error in
          self?.handleErrors(error)
        }
      }
    }

    return cell
  }

  func pagerView(_ pageView: TYCyclePagerView, didScrollFrom _: Int, to _: Int) {
    guard let cell = pageView.curIndexCell() as? TYCyclePagerViewCell else { return }
    let blur = SDImageBlurTransformer(radius: 16)
    blurImageBackgroundView.image = cell.imageView.image != nil ? blur.transformedImage(
      with: cell.imageView.image!,
      forKey: "") : nil
  }

  func layout(for _: TYCyclePagerView) -> TYCyclePagerViewLayout {
    let layout = TYCyclePagerViewLayout()
    layout.itemSize = CGSize(width: 200, height: 200)
    layout.itemSpacing = 20
    layout.itemHorizontalCenter = true
    layout.layoutType = .linear
    return layout
  }

  func pagerView(_: TYCyclePagerView, didSelectedItemCell _: UICollectionViewCell, at index: Int) {
    let game = datas[index]
    self.viewModel.fetchGame(game)
  }
}

extension NumberGameViewController: BarButtonItemable {
  func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
    switch sender {
    case is RecordBarButtonItem:
      guard
        let numberGameSummaryViewController = UIStoryboard(name: "NumberGame", bundle: nil)
          .instantiateViewController(withIdentifier: "NumberGameSummaryViewController") as? NumberGameSummaryViewController
      else { return }
      self.navigationController?.pushViewController(numberGameSummaryViewController, animated: true)
    case is FavoriteBarButtonItem:
      guard
        let favoriteViewController = UIStoryboard(name: "Product", bundle: nil)
          .instantiateViewController(withIdentifier: "FavoriteViewController") as? FavoriteViewController else { return }
      favoriteViewController.viewModel = self.viewModel
      self.navigationController?.pushViewController(favoriteViewController, animated: true)
    case is SearchButtonItem:
      guard
        let searchViewController = UIStoryboard(name: "Product", bundle: nil)
          .instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController else { return }
      searchViewController.viewModel = self.viewModel
      self.navigationController?.pushViewController(searchViewController, animated: true)
    default: break
    }
  }
}

private struct DropdownItem:
  DropdownSelectable,
  Equatable
{
  var identity: String { contentText }
  var contentText: String
  var sorting: GameSorting
}
