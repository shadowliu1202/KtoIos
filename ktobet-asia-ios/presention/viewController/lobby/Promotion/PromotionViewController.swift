import UIKit
import RxSwift
import RxCocoa
import SharedBu

class PromotionViewController: LobbyViewController {
    @IBOutlet private weak var filterDropDwon: PromotionFilterDropDwon!
    @IBOutlet private weak var noDataView: UIView!
    @IBOutlet private weak var tableView: UITableView!
    
    var barButtonItems: [UIBarButtonItem] = []
    private var disposeBag = DisposeBag()
    private var viewModel = Injectable.resolve(PromotionViewModel.self)!
    private var dataSource: [[PromotionVmItem]] = [[]]
    private var lastTag: PromotionTag?
    private var lastProductTags: [PromotionProductTag]?
    private var localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: Localize.string("bonus_title"))
        self.bind(position: .right, barButtonItems: .kto(.history))
        initUI()
        dataBinding()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchData()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func initUI() {
        tableView.estimatedRowHeight = 173.0
        tableView.sectionHeaderHeight = 54.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        filterDropDwon.clickHandler = { [weak self] (promotionTag, promotionProductTags) in
            self?.filterClickHandler(tag: promotionTag, productTags: promotionProductTags)
        }
    }
    
    private func dataBinding() {
        viewModel.dataSource.catchError({ [weak self] (error) in
            self?.handleErrors(error)
            return Observable.just([[]])
        }).subscribe(onNext:{[weak self] (bonusCoupons) in
            self?.switchContent(bonusCoupons)
            self?.dataSource = bonusCoupons
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
        
        tableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
            let item = self?.dataSource[indexPath.section][indexPath.row]
            if let bonusCoupon = item as? HasAmountLimitationItem, bonusCoupon.isFull() {
                return
            }
            guard let promotionDetailViewController = UIStoryboard(name: "Promotion", bundle: nil).instantiateViewController(withIdentifier: "PromotionDetailViewController") as? PromotionDetailViewController else { return }
            promotionDetailViewController.viewModel = self?.viewModel
            promotionDetailViewController.item = item
            self?.navigationController?.pushViewController(promotionDetailViewController, animated: true)
        }).disposed(by: self.disposeBag)
        
        viewModel.filterSource.subscribe(onNext: { [weak self] (filters: [(PromotionFilter, Int)]) in
            if self?.filterDropDwon.tags.count == 0 {
                self?.initFilterDropDwon(filters)
            } else {
                self?.updateFilterDropDwonCount(filters)
            }
        }, onError: { [weak self](error) in
            self?.handleErrors(error)
        }).disposed(by: disposeBag)
    }
    
    private func initFilterDropDwon(_ filters: [(PromotionFilter, Int)]) {
        self.filterDropDwon.tags = filters.map({ (tuple) in
            let (filter, count) = tuple
            if case .all = filter {
                return PromotionTag(isSelected: true, filter: filter, count: count)
            } else {
                return PromotionTag(isSelected: false, filter: filter, count: count)
            }
        })
    }
    
    private func updateFilterDropDwonCount(_ filters: [(PromotionFilter, Int)]) {
        self.filterDropDwon.updateDropDwonTag(filters)
    }
    
    private func switchContent(_ items: [[PromotionVmItem]]) {
        if items.allSatisfy({$0.count == 0}) {
            self.tableView.isHidden = true
            self.noDataView.isHidden = false
        } else {
            self.tableView.isHidden = false
            self.noDataView.isHidden = true
        }
    }
    
    private func filterClickHandler(tag: PromotionTag?, productTags: [PromotionProductTag]) -> () {
        let theSameProductTags: Bool = self.lastProductTags?.elementsEqual(productTags) ?? false
        if let tag = tag, self.lastTag != tag || !theSameProductTags  {
            self.lastTag = tag
            self.lastProductTags = productTags.map({PromotionProductTag(isSelected: $0.isSelected, filter: $0.filter)})
            viewModel.setCouponFilter(tag.filter, productTags.filter({$0.isSelected}).map({$0.filter}))
        }
    }
}

extension PromotionViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewModel.sectionHeaders.count > section {
            return dataSource[section].count > 0 ? 54 : CGFloat.leastNormalMagnitude
        }
        return 24
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewModel.sectionHeaders.count > section, dataSource[section].count > 0 {
            let title = viewModel.sectionHeaders[section]
            return tableView.dequeueReusableCell(withIdentifier: "PromotionHeaderViewCell", cellType: PromotionHeaderViewCell.self).configure(title)
        } else {
            return UIView(frame: .zero)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = dataSource[indexPath.section][indexPath.row]
        var cell: PromotionTableViewCell
        if let bonusCoupon = item as? BonusCouponItem, bonusCoupon.couponState == .usable {
            cell = tableView.dequeueReusableCell(withIdentifier: "UsableTableViewCell", cellType: UsableTableViewCell.self)
                .configure(item)
                .setClickGetCouponHandler({ [weak self] (pressEvent, disposeBag) in
                    pressEvent.bind(onNext: { [weak self] in
                        self?.useBonusCoupon(bonusCoupon.rawValue)
                    }).disposed(by: disposeBag)
                })
        } else if let promotion = item as? PromotionEventItem {
            cell = tableView.dequeueReusableCell(withIdentifier: "UsableTableViewCell", cellType: UsableTableViewCell.self).configure(item, promotion.isAutoUse(), localStorageRepo.getSupportLocale())
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "UnusableTableViewCell", cellType: UnusableTableViewCell.self).configure(item, localStorageRepo.getSupportLocale())
        }
        return cell.refreshHandler({ [weak self] in
            self?.viewModel.fetchData()
        })
    }
    
    func useBonusCoupon(_ bonusCoupon: BonusCoupon) {
        self.viewModel.requestCouponApplication(bonusCoupon: bonusCoupon)
            .flatMapCompletable({ (waiting) in
                return UseBonusCoupon.confirm(waiting: waiting, bonusCoupon: bonusCoupon)
            }).subscribe(onCompleted: { [weak self] in
                self?.viewModel.fetchData()
            }, onError: { [weak self] (error) in
                self?.handleErrors(error)
            }).disposed(by: disposeBag)
    }
}

extension PromotionViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        guard let promotionHistoryViewController = UIStoryboard(name: "PromotionHistory", bundle: nil).instantiateViewController(withIdentifier: "PromotionHistoryViewController") as? PromotionHistoryViewController else { return }
        self.navigationController?.pushViewController(promotionHistoryViewController, animated: true)
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
