import RxCocoa
import RxSwift
import UIKit

class PromotionFilterViewController: FilterConditionViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var btnSubmit: UIButton!

  private let disposeBag = DisposeBag()

  private lazy var totalSource = BehaviorRelay<[FilterItem]>(value: [])
  private var sortingStackView: UIStackView!

  private var _presenter: FilterPresentProtocol!

  private var _conditionCallbck: (([FilterItem]) -> Void)?

  override var presenter: FilterPresentProtocol! {
    get {
      _presenter
    }
    set {
      _presenter = newValue
    }
  }

  override var conditionCallback: (([FilterItem]) -> Void)? {
    get {
      _conditionCallbck
    }
    set {
      _conditionCallbck = newValue
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    initUI()
    dataBinding()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

// MARK: - UI

extension PromotionFilterViewController {
  private func initUI() {
    titleLabel.text = presenter.getTitle()

    tableView.separatorColor = .clear

    displayLastRowSeparator()

    setBackItem(.close)
      .disposed(by: disposeBag)
  }

  private func dataBinding() {
    totalSource.accept(presenter.getDatasource())

    btnSubmit.rx.touchUpInside
      .subscribe(onNext: { [weak self] in
        self?.conditionCallback?(self?.getConditions() ?? [])
        self?.dismiss(animated: true)
      })
      .disposed(by: disposeBag)

    totalSource.asObservable()
      .bind(to: tableView.rx.items) { [weak self] tableView, row, item in
        guard let self else { return UITableViewCell() }

        if item.type == .static {
          return tableView
            .dequeueReusableCell(
              withIdentifier: "StaticCell",
              cellType: StaticCell.self)
            .configure(item, impl: self.presenter)
        }
        else {
          let cell = tableView
            .dequeueReusableCell(
              withIdentifier: "InteractiveCell",
              cellType: InteractiveCell.self)
            .configure(item, impl: self.presenter) { pressedEvent, disposeBag in
              pressedEvent
                .subscribe(onNext: { [weak self] _ in
                  guard let self else { return }
                  self.toggle(row)
                })
                .disposed(by: disposeBag)
            }

          cell.removeAllBorder()

          switch row {
          case 1:
            cell.addBorder(.top)
            cell.addBorder(.bottom)
            cell.titleLeadingConstraint.constant = 30

          case 3:
            cell.addBorder(.top)
            cell.addBorder(.bottom, leftConstant: 30)
            cell.titleLeadingConstraint.constant = 30

          case PromotionPresenter.productRows.first ?? 0:
            cell.titleLeadingConstraint.constant = 58

          case PromotionPresenter.productRows:
            cell.addBorder(.top, leftConstant: 58)
            cell.titleLeadingConstraint.constant = 58

          case (PromotionPresenter.productRows.last ?? 0) + 1:
            cell.addBorder(.top, leftConstant: 58)
            cell.titleLeadingConstraint.constant = 30

          default:
            cell.addBorder(.top, leftConstant: 30)
            cell.titleLeadingConstraint.constant = 30
          }

          return cell
        }
      }
      .disposed(by: disposeBag)
  }

  @objc
  private func sortingDescTapped(_: UITapGestureRecognizer) {
    sortringTapped(Localize.string("bonus_orderby_desc"))
  }

  @objc
  private func sortingAscTapped(_: UITapGestureRecognizer) {
    sortringTapped(Localize.string("bonus_orderby_asc"))
  }

  private func sortringTapped(_ currenttitle: String) {
    sortingStackView.removeFromSuperview()

    let sortingCondition = presenter.getDatasource()[PromotionPresenter.sortingRow]
    if sortingCondition.title != currenttitle {
      presenter.toggleItem(PromotionPresenter.sortingRow)
    }

    let newValue = presenter.getDatasource()
    totalSource.accept(newValue)
  }

  private func getConditions() -> [FilterItem] {
    totalSource.value
  }

  private func toggle(_ row: Int) {
    if row == PromotionPresenter.sortingRow {
      showSortingView()
    }
    else {
      presenter.toggleItem(row)

      let newValue = presenter.getDatasource()
      totalSource.accept(newValue)
    }
  }

  private func showSortingView() {
    let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as! InteractiveCell

    let descLabel = UILabel()
    descLabel.textColor = .greyScaleWhite
    descLabel.text = Localize.string("bonus_orderby_desc")
    descLabel.font = UIFont(name: "PingFangSC-Medium", size: 14)

    let descTap = UITapGestureRecognizer(target: self, action: #selector(sortingDescTapped(_:)))
    descLabel.isUserInteractionEnabled = true
    descLabel.addGestureRecognizer(descTap)

    let ascLabel = UILabel()
    ascLabel.textColor = .greyScaleWhite
    ascLabel.text = Localize.string("bonus_orderby_asc")
    ascLabel.font = UIFont(name: "PingFangSC-Medium", size: 14)

    let ascTap = UITapGestureRecognizer(target: self, action: #selector(sortingAscTapped(_:)))
    ascLabel.isUserInteractionEnabled = true
    ascLabel.addGestureRecognizer(ascTap)

    sortingStackView = UIStackView(
      frame: CGRect(
        x: cell.titleLbl.frame.origin.x - 8,
        y: cell.frame.origin.y,
        width: cell.frame.width * 0.87,
        height: cell.frame.height * 2))
    sortingStackView.distribution = .fillEqually
    sortingStackView.alignment = .fill
    sortingStackView.axis = .vertical
    sortingStackView.insertArrangedSubview(descLabel, at: 0)
    sortingStackView.insertArrangedSubview(ascLabel, at: 1)
    sortingStackView.backgroundColor = UIColor.greyScaleDefault
    sortingStackView.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
    sortingStackView.isLayoutMarginsRelativeArrangement = true

    tableView.addSubview(sortingStackView ?? UIView())
  }

  private func lastRowSeparator() -> CALayer {
    let sepFrame = CGRect(x: 0, y: -1, width: self.tableView.bounds.width, height: 1)
    let sep = CALayer()
    sep.frame = sepFrame
    sep.backgroundColor = UIColor.greyScaleDivider.cgColor
    return sep
  }

  private func displayLastRowSeparator() {
    let separator = UIView(frame: .zero)
    separator.layer.addSublayer(lastRowSeparator())
    tableView.tableFooterView = separator
  }
}

// MARK: - TableViewDelegate

extension PromotionFilterViewController: UITableViewDelegate {
  func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if indexPath.row == 2 {
      return 69
    }
    else {
      return 48
    }
  }
}

class FilterConditionViewController: UIViewController, EmbedNavigation {
  var presenter: FilterPresentProtocol!
  var conditionCallback: (([FilterItem]) -> Void)?
}

class StaticCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var selectAllButton: UIButton!

  private lazy var disposeBag = DisposeBag()

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
  }

  func configure(
    _ item: FilterItem,
    impl: FilterPresentProtocol?,
    selectAllCallback: ((Observable<Void>, DisposeBag) -> Void)? = nil)
    -> Self
  {
    self.selectionStyle = .none
    self.titleLabel.text = impl?.itemText(item)
    selectAllButton.setTitle(
      (item.isSelected ?? false) ? Localize.string("common_select_all") : Localize.string("common_unselect_all"),
      for: .normal)
    selectAllCallback?(selectAllButton.rx.tap.asObservable(), disposeBag)
    return self
  }
}

class InteractiveCell: UITableViewCell {
  @IBOutlet weak var titleLbl: UILabel!
  @IBOutlet weak var selectBtn: UIButton!
  @IBOutlet weak var titleLeadingConstraint: NSLayoutConstraint!
  private lazy var disposeBag = DisposeBag()

  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
  }

  func configure(_ item: FilterItem, impl: FilterPresentProtocol?, callback: (Observable<Void>, DisposeBag) -> Void) -> Self {
    self.selectionStyle = .none
    titleLbl.text = impl?.itemText(item)
    if let img = impl?.itemAccenery(item) as? UIImage {
      self.selectBtn.setImage(img, for: .normal)
    }
    callback(self.selectBtn.rx.touchUpInside.asObservable(), disposeBag)
    return self
  }
}
