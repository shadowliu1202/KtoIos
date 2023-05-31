import RxCocoa
import RxSwift
import SharedBu
import UIKit

class PromotionViewController: LobbyViewController {
  @IBOutlet weak var filterDropDwon: PromotionFilterDropDwon!
  @IBOutlet weak var tableView: UITableView!
  
  private var emptyStateView: EmptyStateView!

  private var dataSource: [[PromotionVmItem]] = [[]]
  private var lastTag: PromotionTag?
  private var lastProductTags: [PromotionProductTag]?

  private var localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!
  private var disposeBag = DisposeBag()

  var barButtonItems: [UIBarButtonItem] = []
  var viewModel = Injectable.resolve(PromotionViewModel.self)!

  var useBonusCoupon = UseBonusCoupon()

  override func viewDidLoad() {
    super.viewDidLoad()
    
    initUI()
    dataBinding()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.fetchData()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func initUI() {
    NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: Localize.string("bonus_title"))
    self.bind(position: .right, barButtonItems: .kto(.history))
    
    tableView.estimatedRowHeight = 173.0
    tableView.sectionHeaderHeight = 54.0
    tableView.rowHeight = UITableView.automaticDimension
    tableView.dataSource = self
    tableView.delegate = self
    
    filterDropDwon.clickHandler = { [weak self] promotionTag, promotionProductTags in
      self?.filterClickHandler(tag: promotionTag, productTags: promotionProductTags)
    }
    
    initEmptyStateView()
  }
  
  private func initEmptyStateView() {
    emptyStateView = EmptyStateView(
      icon: UIImage(named: "Coupon"),
      description: Localize.string("common_no_related_promotions"),
      keyboardAppearance: .impossible)
    emptyStateView.isHidden = true
    
    view.addSubview(emptyStateView)

    emptyStateView.snp.makeConstraints { make in
      make.top.equalTo(filterDropDwon.snp.bottom)
      make.bottom.leading.trailing.equalToSuperview()
    }
  }

  private func dataBinding() {
    viewModel.dataSource.catch({ [weak self] error in
      self?.handleErrors(error)
      return Observable.just([[]])
    }).subscribe(onNext: { [weak self] bonusCoupons in
      self?.switchContent(bonusCoupons)
      self?.dataSource = bonusCoupons
      self?.tableView.reloadData()
    }).disposed(by: disposeBag)

    tableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
      let item = self?.dataSource[indexPath.section][indexPath.row]
      if let bonusCoupon = item as? HasAmountLimitationItem, bonusCoupon.isFull() {
        return
      }
      guard
        let promotionDetailViewController = UIStoryboard(name: "Promotion", bundle: nil)
          .instantiateViewController(withIdentifier: "PromotionDetailViewController") as? PromotionDetailViewController
      else { return }
      promotionDetailViewController.viewModel = self?.viewModel
      promotionDetailViewController.item = item
      self?.navigationController?.pushViewController(promotionDetailViewController, animated: true)
    }).disposed(by: self.disposeBag)

    viewModel.filterSource.subscribe(onNext: { [weak self] (filters: [(PromotionFilter, Int)]) in
      if self?.filterDropDwon.tags.count == 0 {
        self?.initFilterDropDwon(filters)
      }
      else {
        self?.updateFilterDropDwonCount(filters)
      }
    }, onError: { [weak self] error in
      self?.handleErrors(error)
    }).disposed(by: disposeBag)
  }

  private func initFilterDropDwon(_ filters: [(PromotionFilter, Int)]) {
    self.filterDropDwon.tags = filters.map({ tuple in
      let (filter, count) = tuple
      if case .all = filter {
        return PromotionTag(isSelected: true, filter: filter, count: count)
      }
      else {
        return PromotionTag(isSelected: false, filter: filter, count: count)
      }
    })
  }

  private func updateFilterDropDwonCount(_ filters: [(PromotionFilter, Int)]) {
    self.filterDropDwon.updateDropDwonTag(filters)
  }

  private func switchContent(_ items: [[PromotionVmItem]]) {
    if items.allSatisfy({ $0.count == 0 }) {
      self.tableView.isHidden = true
      self.emptyStateView.isHidden = false
    }
    else {
      self.tableView.isHidden = false
      self.emptyStateView.isHidden = true
    }
  }

  private func filterClickHandler(tag: PromotionTag?, productTags: [PromotionProductTag]) {
    let theSameProductTags: Bool = self.lastProductTags?.elementsEqual(productTags) ?? false
    if let tag, self.lastTag != tag || !theSameProductTags {
      self.lastTag = tag
      self.lastProductTags = productTags.map({ PromotionProductTag(isSelected: $0.isSelected, filter: $0.filter) })
      viewModel.setCouponFilter(tag.filter, productTags.filter({ $0.isSelected }).map({ $0.filter }))
    }
  }
}

extension PromotionViewController: UITableViewDataSource, UITableViewDelegate {
  func numberOfSections(in _: UITableView) -> Int {
    dataSource.count
  }

  func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if viewModel.sectionHeaders.count > section {
      return dataSource[section].count > 0 ? 54 : CGFloat.leastNormalMagnitude
    }
    return 24
  }

  func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
    CGFloat.leastNormalMagnitude
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if viewModel.sectionHeaders.count > section, dataSource[section].count > 0 {
      let title = viewModel.sectionHeaders[section]
      return tableView
        .dequeueReusableCell(withIdentifier: "PromotionHeaderViewCell", cellType: PromotionHeaderViewCell.self)
        .configure(title)
    }
    else {
      return UIView(frame: .zero)
    }
  }

  func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
    dataSource[section].count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = dataSource[indexPath.section][indexPath.row]
    var cell: PromotionTableViewCell
    if let bonusCoupon = item as? BonusCouponItem, bonusCoupon.couponState == .usable {
      cell = tableView.dequeueReusableCell(withIdentifier: "UsableTableViewCell", cellType: UsableTableViewCell.self)
        .configure(item)
        .setClickGetCouponHandler({ [weak self] pressEvent, disposeBag in
          pressEvent.bind(onNext: { [weak self] in
            self?.useCoupon(bonusCoupon.rawValue)
          }).disposed(by: disposeBag)
        })
    }
    else if let promotion = item as? PromotionEventItem {
      cell = tableView.dequeueReusableCell(withIdentifier: "UsableTableViewCell", cellType: UsableTableViewCell.self)
        .configure(item, promotion.isAutoUse(), localStorageRepo.getSupportLocale())
    }
    else {
      cell = tableView.dequeueReusableCell(withIdentifier: "UnusableTableViewCell", cellType: UnusableTableViewCell.self)
        .configure(item, localStorageRepo.getSupportLocale())
    }
    return cell.refreshHandler({ [weak self] in
      self?.viewModel.fetchData()
    })
  }

  func useCoupon(_ bonusCoupon: BonusCoupon) {
    self.viewModel.requestCouponApplication(bonusCoupon: bonusCoupon)
      .flatMapCompletable({ [weak self] waiting in
        guard let self else { return .empty() }

        return self.useBonusCoupon.confirm(waiting: waiting, bonusCoupon: bonusCoupon)
      })
      .subscribe(onCompleted: { [weak self] in
        self?.viewModel.fetchData()
      }, onError: { [weak self] error in
        self?.handleErrors(error)
      })
      .disposed(by: disposeBag)
  }
}

extension PromotionViewController: BarButtonItemable {
  func pressedRightBarButtonItems(_: UIBarButtonItem) {
    navigationController?.pushViewController(
      PromotionHistoryViewController.instantiate(),
      animated: true)
  }
}

class PromotionHeaderViewCell: UITableViewCell {
  @IBOutlet weak var titleLabel: UILabel!

  func configure(_ title: String?) -> Self {
    self.selectionStyle = .none
    titleLabel.text = title
    return self
  }
}
