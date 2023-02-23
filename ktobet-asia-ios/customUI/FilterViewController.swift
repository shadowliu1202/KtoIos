import RxCocoa
import RxSwift
import SharedBu
import UIKit

class FilterViewController<Presenter>:
  UIViewController,
  SwiftUIConverter
  where
  Presenter: Selecting & ObservableObject
{
  let presenter: Presenter
  let barItemType: BarItemType
  var barItemImageName: String?
  var haveSelectAll: Bool
  var selectAtLeastOne: Bool
  var allowMultipleSelection: Bool

  var onDone: (() -> Void)?

  init(
    presenter: Presenter,
    barItemType: BarItemType,
    barItemImageName: String? = nil,
    haveSelectAll: Bool = true,
    selectAtLeastOne: Bool = true,
    allowMultipleSelection: Bool = false,
    onDone: (() -> Void)?)
  {
    self.presenter = presenter
    self.barItemType = barItemType
    self.barItemImageName = barItemImageName
    self.haveSelectAll = haveSelectAll
    self.selectAtLeastOne = selectAtLeastOne
    self.allowMultipleSelection = allowMultipleSelection
    self.onDone = onDone

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
  }

  deinit {
    print("\(type(of: self)) deinit")
  }
}

// MARK: - UI

extension FilterViewController {
  private func setupUI() {
    NavigationManagement.sharedInstance
      .addBarButtonItem(
        vc: self,
        barItemType: barItemType,
        image: barItemImageName)

    addSubView(
      from: { [unowned self] in
        FilterSelector(
          presenter: self.presenter,
          selectedItems: self.presenter.selectedItems,
          haveSelectAll: self.haveSelectAll,
          selectAtLeastOne: self.selectAtLeastOne,
          allowMultipleSelection: self.allowMultipleSelection,
          onDone: self.onDone)
      },
      to: view)
  }
}
