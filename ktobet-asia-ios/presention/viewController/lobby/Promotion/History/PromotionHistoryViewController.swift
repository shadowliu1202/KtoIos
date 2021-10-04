import UIKit
import RxSwift
import SharedBu


class PromotionHistoryViewController: UIViewController {
    @IBOutlet private weak var dateView: KTODateView!
    @IBOutlet private weak var filterBtn: FilterButton!
    @IBOutlet private weak var emptyView: UIView!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var summaryLabel: UILabel!
    
    var barButtonItems: [UIBarButtonItem] = []
    
    fileprivate var viewModel = DI.resolve(PromotionHistoryViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    fileprivate var currentFilter: [FilterItem]?
    fileprivate var filterPersenter = PromotionPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        self.bind(position: .right, barButtonItems: .kto(.search))
        tableView.register(UINib(nibName: "PromotionHistoryTableViewCell", bundle: nil), forCellReuseIdentifier: "PromotionHistoryTableViewCell")
        let storyboard = UIStoryboard(name: "Filter", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PromotionFilterViewController") as! FilterConditionViewController
        filterBtn.set(filterPersenter)
            .setGotoFilterVC(vc: vc)
            .set { [weak self] (items) in
                guard let self = self else { return }
                let condition = (items as? [PromotionItem])?.filter{ $0.productType != ProductType.none }
                self.currentFilter = condition
                self.filterBtn.set(items)
                self.filterBtn.setPromotionStyleTitle(source: condition)
                let status = self.filterPersenter.getConditionStatus(condition!)
                self.viewModel.productTypes = status.prodcutType
                self.viewModel.bonusTypes = status.bonusType
                self.viewModel.sortingBy = status.sorting
            }
        
        dateView.callBackCondition = {[weak self] (beginDate, endDate, dateType) in
            if let fromDate = beginDate, let toDate = endDate {
                self?.viewModel.beginDate = fromDate
                self?.viewModel.endDate = toDate
            }
        }
        
        viewModel.relayTotalCountAmount.bind(to: summaryLabel.rx.text).disposed(by: disposeBag)        
        viewModel.recordPagination.elements.do{[weak self](element) in
            self?.tableView.isHidden = element.isEmpty
            self?.emptyView.isHidden = !element.isEmpty
        }.bind(to: tableView.rx.items) {[weak self] (tableView, row, element) in
            guard let self = self else { return  UITableViewCell()}
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "PromotionHistoryTableViewCell", cellType: PromotionHistoryTableViewCell.self)
            cell.config(element, tableView: self.tableView)
            return cell
        }.disposed(by: disposeBag)
        
        rx.sentMessage(#selector(UIViewController.viewDidAppear(_:)))
            .map { _ in () }
            .bind(to: viewModel.recordPagination.refreshTrigger)
            .disposed(by: disposeBag)
        
        scrollView.rx_reachedBottom
            .map{ _ in ()}
            .bind(to: self.viewModel.recordPagination.loadNextPageTrigger)
            .disposed(by: disposeBag)
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
        switch sender {
        case is SearchButtonItem:
            guard let searchViewController = UIStoryboard(name: "PromotionHistory", bundle: nil).instantiateViewController(withIdentifier: "PromotionSearchViewController") as? PromotionSearchViewController else { return }
            searchViewController.viewModel = self.viewModel
            self.navigationController?.pushViewController(searchViewController, animated: true)
            break
        default: break
        }
    }
}
