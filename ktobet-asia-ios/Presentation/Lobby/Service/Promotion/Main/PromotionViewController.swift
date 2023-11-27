import Combine
import RxCocoa
import RxSwift
import sharedbu
import SwiftUI
import UIKit

class PromotionViewController: LobbyViewController {
  @IBOutlet weak var tableView: UITableView!
  
  private var dropDownFilterView: UIView!
  private var emptyStateView: EmptyStateView!

  private var dataSource: [[PromotionVmItem]] = [[]]

  private var localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!
  private var disposeBag = DisposeBag()
  private var cancellables = Set<AnyCancellable>()

  private var dropDownFilterViewCollapseHeight = CGFloat()
  
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

  private func initUI() {
    NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: Localize.string("bonus_title"))
    self.bind(position: .right, barButtonItems: .kto(.history))
    
    tableView.estimatedRowHeight = 173.0
    tableView.sectionHeaderHeight = 54.0
    tableView.rowHeight = UITableView.automaticDimension
    tableView.dataSource = self
    tableView.delegate = self
    
    initEmptyStateView()
    initFilterDropDownView()
    
    tableView.snp.makeConstraints { make in
      make.top.equalTo(dropDownFilterView.snp.bottom)
      make.bottom.equalToSuperview()
      make.leading.equalToSuperview().offset(30)
      make.trailing.equalToSuperview().offset(-30)
    }
  }
  
  private func initFilterDropDownView() {
    dropDownFilterView = UIHostingController(
      rootView:
      VStack {
        PromotionDropDownFilter(
          viewModel: viewModel,
          onExpandStateChange: { [weak self] isExpand in
            guard let self else { return }
              
            self.dropDownFilterView.snp.remakeConstraints { make in
              if isExpand {
                make.height.equalToSuperview()
              }
                
              make.width.equalToSuperview()
                
              make.top.equalTo(self.view.safeAreaLayoutGuide)
              make.centerX.equalToSuperview()
            }
            
            self.view.layoutIfNeeded()
          })
          
        Spacer(minLength: 0)
      })
      .view
    
    dropDownFilterView.backgroundColor = .clear
    view.insertSubview(dropDownFilterView, aboveSubview: tableView)
    
    dropDownFilterView.snp.makeConstraints { make in
      make.width.equalToSuperview()
      
      make.top.equalTo(view.safeAreaLayoutGuide)
      make.centerX.equalToSuperview()
    }
    
    dropDownFilterViewCollapseHeight = dropDownFilterView.frame.height
  }
  
  private func initEmptyStateView() {
    emptyStateView = EmptyStateView(
      icon: UIImage(named: "Coupon"),
      description: Localize.string("common_no_related_promotions"),
      keyboardAppearance: .impossible)
    emptyStateView.isHidden = true
    
    view.insertSubview(emptyStateView, at: 0)

    emptyStateView.snp.makeConstraints { make in
      make.top.equalToSuperview().offset(dropDownFilterViewCollapseHeight)
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

    viewModel.filterSource
      .subscribe(
        onNext: { [weak self] (filters: [(PromotionFilter, Int)]) in
          self?.viewModel.promotionTags = filters
            .map { promotionTagRecipes in
              let (filter, count) = promotionTagRecipes
              
              return PromotionTag(isSelected: false, filter: filter, count: count)
            }
        },
        onError: { [weak self] error in
          self?.handleErrors(error)
        })
      .disposed(by: disposeBag)
                                
    Publishers.CombineLatest(
      viewModel.$selectedPromotionFilter,
      viewModel.$selectedProductFilters)
      .sink { [weak self] selectedPromotionFilter, selectedProductFilters in
        self?.viewModel
          .setCouponFilter(selectedPromotionFilter, Array(selectedProductFilters))
      }
      .store(in: &cancellables)
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
