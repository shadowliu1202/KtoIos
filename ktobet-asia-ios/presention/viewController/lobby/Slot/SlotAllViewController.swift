import RxSwift
import SharedBu
import UIKit

class SlotAllViewController: DisplayProduct {
  static let segueIdentifier = "toShowAllSlot"

  @IBOutlet weak var dropDownView: UIView!
  @IBOutlet weak var dropDownTableView: UITableView!
  @IBOutlet weak var dropDownTitleLabel: UILabel!
  @IBOutlet weak var iconArrowImageView: UIImageView!
  @IBOutlet weak var gamesCollectionView: WebGameCollectionView!
  @IBOutlet var gamesCollectionViewHeight: NSLayoutConstraint!

  lazy var gameDataSourceDelegate = ProductGameDataSourceDelegate(self)
  var viewModel: SlotViewModel!
  var barButtonItems: [UIBarButtonItem] = []
  var options: [SlotGameFilter] = []
  var dropDownItem: [(contentText: String, isSelected: Bool, sorting: GameSorting)] =
    [
      (Localize.string("product_hot_sorting"), true, .popular),
      (
        Localize
          .string("product_name_sorting"),
        false,
        .gamename),
      (
        Localize
          .string("product_release_sorting"),
        false,
        .releaseddate)
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
  }

  deinit {
    print("all deinit")
  }

  private func initUI() {
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapDropDown))
    dropDownView.addGestureRecognizer(tapGesture)
    dropDownTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .none)
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

  @objc
  private func didTapDropDown() {
    dropDownTableView.isHidden = !dropDownTableView.isHidden
    iconArrowImageView.image = dropDownTableView
      .isHidden ? UIImage(named: "iconAccordionArrowDown") : UIImage(named: "iconAccordionArrowUp")
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

extension SlotAllViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    3
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "DropDownCell") as! DropDownTableViewCell
    cell.contentText.text = dropDownItem[indexPath.row].contentText
    cell.selectedImageView.isHidden = !dropDownItem[indexPath.row].isSelected

    return cell
  }

  func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
    dropDownTitleLabel.text = dropDownItem[indexPath.row].contentText
    dropDownItem[indexPath.row].isSelected = true
    dropDownTableView.isHidden = true
    iconArrowImageView.image = UIImage(named: "iconAccordionArrowDown")
    getAllGame(sorting: dropDownItem[indexPath.row].sorting, filter: options)
  }

  func tableView(_: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
    dropDownItem[indexPath.row].isSelected = false
    dropDownTableView.reloadData()

    return indexPath
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
          let sorting = self?.dropDownItem.first(where: { $0.isSelected }).map { $0.sorting } ?? .popular
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
