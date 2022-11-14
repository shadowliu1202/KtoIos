import UIKit
import RxSwift
import SharedBu


class PromotionHistoryViewController: LobbyViewController {
    @IBOutlet private weak var dateView: KTODateView!
    @IBOutlet private weak var filterBtn: FilterButton!
    @IBOutlet private weak var emptyView: UIView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var summaryLabel: UILabel!
    
    @Injected fileprivate var viewModel: PromotionHistoryViewModel
    
    fileprivate var currentFilter: [FilterItem]?
    fileprivate var filterPersenter = PromotionPresenter()
    
    fileprivate var disposeBag = DisposeBag()
    
    var barButtonItems: [UIBarButtonItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        
        bind(position: .right, barButtonItems: .kto(.search))
        
        tableView.register(
            UINib(nibName: "PromotionHistoryTableViewCell", bundle: nil),
            forCellReuseIdentifier: "PromotionHistoryTableViewCell"
        )
        
        let filterController = PromotionFilterViewController.initFrom(storyboard: "Filter")
        
        filterBtn
            .set(filterPersenter)
            .setGotoFilterVC(vc: filterController)
            .`set` { [weak self] (items) in
                guard let self = self else { return }
                
                let condition = (items as? [PromotionItem])?.filter{ $0.productType != ProductType.none }
                self.currentFilter = condition
                self.filterBtn.set(items)
                self.filterBtn.setPromotionStyleTitle(source: condition)
                
                let status = self.filterPersenter.getConditionStatus(condition!)
                self.viewModel.productTypes = status.prodcutTypes
                self.viewModel.privilegeTypes = status.privilegeTypes
                self.viewModel.sortingBy = status.sorting
                
                self.fetchData()
            }
        
        dateView.callBackCondition = { [weak self] (beginDate, endDate, dateType) in
            if let fromDate = beginDate,
               let toDate = endDate {
                self?.viewModel.beginDate = fromDate
                self?.viewModel.endDate = toDate
                self?.fetchData()
            }
        }
        
        viewModel.relayTotalCountAmount
            .bind(to: summaryLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.recordPagination.elements
            .do(onNext: { [weak self](element) in
                self?.tableView.isHidden = element.isEmpty
                self?.emptyView.isHidden = !element.isEmpty
            })
            .bind(to: tableView.rx.items) { [weak self] (tableView, row, element) in
                guard let self = self else { return .init() }
                
                let cell = self.tableView.dequeueReusableCell(
                    withIdentifier: "PromotionHistoryTableViewCell",
                    cellType: PromotionHistoryTableViewCell.self
                )
                
                cell.config(element, tableView: self.tableView)
                
                return cell
            }
            .disposed(by: disposeBag)
        
        viewModel.recordPagination.error
            .subscribe(onNext: { [weak self] error in
                self?.handleErrors(error)
            })
            .disposed(by: disposeBag)
        
        scrollView.rx.reachedBottom
            .bind(to: self.viewModel.recordPagination.loadNextPageTrigger)
            .disposed(by: disposeBag)
        
        checkNetworkThenFetchData()
    }
    
    private func checkNetworkThenFetchData() {
        networkConnectRelay
            .filter { $0 }
            .subscribe(onNext: { [weak self] _ in
                self?.fetchData()
            })
            .disposed(by: disposeBag)
    }
    
    private func fetchData() {
        viewModel.recordPagination.refreshTrigger.onNext(())
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

final class ContentSizedTableView: UITableView {
    override var contentSize:CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}

extension PromotionHistoryViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        guard sender is SearchButtonItem else { return }
        
        let searchController = PromotionSearchViewController.initFrom(storyboard: "PromotionHistory")
        
        navigationController?.pushViewController(searchController, animated: true)
    }
}
