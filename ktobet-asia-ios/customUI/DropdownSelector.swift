import RxCocoa
import RxSwift
import SharedBu
import SnapKit
import UIKit

protocol DropdownSelectable {
  func isEqualTo(_ other: DropdownSelectable) -> Bool
  var identity: String { get }
  var contentText: String { get }
}

extension DropdownSelectable {
  func isEqualTo(_ other: DropdownSelectable) -> Bool {
    self.identity == other.identity
  }
}

class DropdownSelector: UIView {
  @Injected var repo: LocalStorageRepository

  let AnimationDuration: TimeInterval = 0.5
  private let items: BehaviorRelay<[DropdownSelectable]> = .init(value: [])
  private let selectedItem: BehaviorRelay<DropdownSelectable?> = .init(value: nil)
  private let disposeBag = DisposeBag()

  private let imageView = UIImageView(frame: .zero)
  private let button = UIButton(frame: .zero)
  private lazy var touchableViews: [UIView] = {
    [tableView, button]
  }()

  private var setDefaultItem = false
  private var expanded = false
  private var tableViewHeight: Double = 0
  private var tableViewHeightConstraint: SnapKit.Constraint?

  let titleLabel = UILabel(frame: .zero)
  let tableView = UITableView(frame: .zero)

  var selectedItemObservable: Observable<DropdownSelectable> {
    selectedItem.asObservable().compactMap { $0 }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
    setupBinding()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
    setupBinding()
  }

  func setItems(_ items: [DropdownSelectable]) {
    self.items.accept(items)
  }

  func setSelectedItem(_ item: DropdownSelectable?) {
    setDefaultItem = true
    selectedItem.accept(item)
  }

  func getSelectedItem() -> DropdownSelectable? {
    selectedItem.value
  }

  func arrowImage(expanded: Bool) -> UIImage? {
    expanded ? UIImage(named: "iconAccordionArrowUp") : UIImage(named: "iconAccordionArrowDown")
  }

  func listExpand(_ expanded: Bool) {
    expanded ? showList() : hideList()
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    for view in touchableViews {
      if let v = view.hitTest(view.convert(point, from: self), with: event) {
        return v
      }
    }
    updateExpanded(with: false)
    return super.hitTest(point, with: event)
  }
}

extension DropdownSelector {
  private func setupUI() {
    let mainStack = UIStackView(frame: .zero)
    mainStack.axis = .horizontal

    addSubview(mainStack)
    mainStack.snp.makeConstraints { make in
      make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24))
    }

    addSubview(button)
    button.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    mainStack.addArrangedSubview(titleLabel)
    titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    titleLabel.textColor = UIColor.whitePure
    titleLabel.localizedFont(by: repo.getSupportLocale(), weight: .medium, size: 14)

    mainStack.addArrangedSubview(imageView)
    imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    imageView.image = arrowImage(expanded: expanded)

    DispatchQueue.main.async {
      self.tableView.backgroundColor = .gray1A1A1A
      self.tableView.separatorStyle = .none
    }
    tableView.tableHeaderView = UIView(
      frame: .init(
        origin: .zero,
        size: .init(width: 1, height: 17)))
    tableView.tableFooterView = UIView(
      frame: .init(
        origin: .zero,
        size: .init(width: 1, height: 17)))
    tableView.alpha = 0
    tableView.allowsSelection = true
    tableView.allowsMultipleSelection = false
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 32
    tableView.register(SortCell.self, forCellReuseIdentifier: "SortCell")

    addSubview(tableView)
    tableView.snp.makeConstraints { make in
      make.top.equalTo(self.snp.bottom)
      make.leading.trailing.equalToSuperview()
      tableViewHeightConstraint = make.height.equalTo(1).constraint
    }
  }

  private func setupBinding() {
    button.rx.touchUpInside
      .bind(onNext: { [weak self] _ in
        guard let self else { return }
        self.expanded.toggle()
        self.updateExpanded(with: self.expanded)
      })
      .disposed(by: disposeBag)

    tableView.rx.observe(\.contentSize)
      .subscribe(onNext: { [weak self] in
        self?.tableViewHeight = $0.height
      })
      .disposed(by: disposeBag)

    items
      .bind(to: tableView.rx.items) { [unowned self] tableView, row, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: "SortCell", for: [0, row]) as! SortCell
        cell.selectionStyle = .none
        cell.locale = self.repo.getSupportLocale()
        cell.label.text = item.contentText

        return cell
      }
      .disposed(by: disposeBag)

    tableView.rx.itemSelected
      .map { [weak self] in
        self?.items.value[$0.row]
      }
      .do(onNext: { [weak self] _ in
        self?.updateExpanded(with: false)
      })
      .bind(to: selectedItem)
      .disposed(by: disposeBag)

    selectedItem
      .compactMap { $0 }
      .map { $0.contentText }
      .bind(to: titleLabel.rx.text)
      .disposed(by: disposeBag)
  }

  private func updateExpanded(with expand: Bool) {
    expanded = expand
    imageView.image = arrowImage(expanded: expand)
    listExpand(expand)
  }

  private func setSelectRow() {
    guard
      let selectItem = selectedItem.value,
      let index = items.value.firstIndex(where: { $0.isEqualTo(selectItem) })
    else {
      return
    }

    tableView.selectRow(at: [0, index], animated: true, scrollPosition: .none)
  }

  private func showList() {
    UIView.animate(
      withDuration: AnimationDuration,
      delay: 0,
      usingSpringWithDamping: 0.9,
      initialSpringVelocity: 0.1,
      options: .curveEaseOut,
      animations: { [weak self] () in
        guard let self else { return }
        self.tableView.alpha = 1
        self.tableViewHeightConstraint?.update(offset: self.tableViewHeight)
        if self.setDefaultItem {
          self.setSelectRow()
          self.setDefaultItem = false
        }
        self.layoutIfNeeded()
      })
  }

  private func hideList() {
    UIView.animate(
      withDuration: AnimationDuration,
      delay: 0,
      usingSpringWithDamping: 0.9,
      initialSpringVelocity: 0.1,
      options: .curveEaseIn,
      animations: { [weak self] () in
        self?.tableView.alpha = 0
        self?.tableViewHeightConstraint?.update(offset: 0)
        self?.layoutIfNeeded()
      })
  }
}

private class SortCell: UITableViewCell {
  let label = UILabel(frame: .zero)
  let selectedImageView = UIImageView(frame: .zero)

  var locale: SupportLocale?

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    selectedImageView.image = selected ? UIImage(named: "iconSelection") : nil
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }

  private func setupUI() {
    self.backgroundColor = .clear
    contentView.addSubview(label)
    contentView.addSubview(selectedImageView)

    label.textColor = .whitePure
    label.localizedFont(by: locale ?? .China(), weight: .regular, size: 14)
    label.snp.makeConstraints { make in
      make.top.bottom.equalToSuperview().inset(6)
      make.leading.equalToSuperview().offset(32)
      make.trailing.equalTo(selectedImageView.snp.leading).offset(-20)
    }

    selectedImageView.snp.makeConstraints { make in
      make.size.equalTo(CGSize(width: 24, height: 24))
      make.centerY.equalToSuperview()
    }
  }
}
