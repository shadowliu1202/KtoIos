import RxSwift
import SharedBu
import UIKit

class SlotAllViewController: DisplayProduct {
  static let segueIdentifier = "toShowAllSlot"

  @IBOutlet weak var dropDownView: DropdownSelector!
  @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
  @IBOutlet var gamesCollectionViewHeight: NSLayoutConstraint!

  lazy var gameDataSourceDelegate = ProductGameDataSourceDelegate(self)
  var viewModel: SlotViewModel!
  var barButtonItems: [UIBarButtonItem] = []
  var options: [SlotGameFilter] = []
  private var dropDownItem: [DropdownItem] =
    [
      .init(contentText: Localize.string("product_hot_sorting"), sorting: .popular),
      .init(contentText: Localize.string("product_name_sorting"), sorting: .gamename),
      .init(contentText: Localize.string("product_release_sorting"), sorting: .releaseddate)
    ]

  private var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(
      vc: self,
      barItemType: .back,
      title: Localize.string("product_all_slot"))
    self.bind(position: .right, barButtonItems: .kto(.search), .kto(.filter))
    initUI()
    getAllGame(sorting: .popular)
    dataBinding()
  }
  
  func dataBinding() {
    dropDownView.selectedItemObservable
      .subscribe(onNext: { [weak self] in
        guard let self, let sorting = ($0 as? DropdownItem)?.sorting else { return }
        self.getAllGame(sorting: sorting, filter: self.options)
      })
      .disposed(by: disposeBag)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func initUI() {
    dropDownView.setItems(dropDownItem)
    dropDownView.setSelectedItem(dropDownItem.first)
    gamesCollectionView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    gamesCollectionView.registerCellFromNib(WebGameItemCell.className)
  }

  private func getAllGame(sorting: GameSorting, filter: [SlotGameFilter] = []) {
    viewModel.gatAllGame(sorting: sorting, filters: filter).subscribe { [weak self] slotGames in
      self?.reloadGameData(slotGames)
    } onError: { [weak self] error in
      self?.handleErrors(error)
    }.disposed(by: disposeBag)
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
    .slot
  }
}

extension SlotAllViewController: BarButtonItemable {
  func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
    switch sender {
    case is FilterBarButtonItem:
      if
        let nav = UIStoryboard(name: "Slot", bundle: nil)
          .instantiateViewController(withIdentifier: "SlotFilterNavViewController") as? UINavigationController,
        let vc = nav.viewControllers.first as? SlotFilterViewController
      {
        nav.modalPresentationStyle = .fullScreen
        vc.options = options
        vc.conditionCallback = { [weak self] options in
          let sorting = (self?.dropDownView.getSelectedItem() as? DropdownItem)?.sorting ?? .popular
          self?.getAllGame(sorting: sorting, filter: options)
          self?.options = options
        }
        vc.presentationController?.delegate = self
        self.present(nav, animated: true, completion: nil)
      }

    case is SearchButtonItem:
      guard
        let searchViewController = UIStoryboard(name: "Product", bundle: nil)
          .instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController else { return }
      searchViewController.viewModel = self.viewModel
      self.navigationController?.pushViewController(searchViewController, animated: true)
    default:
      break
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
