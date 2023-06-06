import RxCocoa
import RxSwift
import SharedBu
import UIKit

class FilterViewController<Presenter>:
  UIViewController,
  SwiftUIConverter,
  EmbedNavigation
  where
  Presenter: Selecting & ObservableObject
{
  let presenter: Presenter
  var haveSelectAll: Bool
  var selectAtLeastOne: Bool
  var allowMultipleSelection: Bool

  var onDone: (() -> Void)?

  private let disposeBag = DisposeBag()

  init(
    presenter: Presenter,
    haveSelectAll: Bool = true,
    selectAtLeastOne: Bool = true,
    allowMultipleSelection: Bool = false,
    onDone: (() -> Void)?)
  {
    self.presenter = presenter
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
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

// MARK: - UI

extension FilterViewController {
  private func setupUI() {
    setBackItem(.close)
      .disposed(by: disposeBag)

    addSubView(
      from: { [unowned self] in
        FilterSelector(
          presenter: self.presenter,
          selectedItems: self.presenter.selectedItems,
          haveSelectAll: self.haveSelectAll,
          selectAtLeastOne: self.selectAtLeastOne,
          allowMultipleSelection: self.allowMultipleSelection,
          onDone: {
            self.onDone?()
            self.dismiss(animated: true)
          })
      },
      to: view)
  }
}
