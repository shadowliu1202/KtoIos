import UIKit
import RxSwift
import SharedBu

class ArcadeBetSummaryByDateViewController: UIViewController {
    static let segueIdentifier = "toArcadeBetSummaryByDate"
    var viewModel: ArcadeRecordViewModel!
    private var disposeBag = DisposeBag()
    
    @IBOutlet private weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self, title: viewModel.selectedLocalDate)
        initUI()
        dataBinding()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
        viewModel.recordByDatePagination.elements.accept([])
    }

    private func initUI() {
        tableView.setHeaderFooterDivider()
        tableView.estimatedRowHeight = 124.0
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    private func dataBinding() {
        viewModel.recordByDatePagination.elements.bind(to: tableView.rx.items) {[weak self] (tableView, row, element) in
            guard let self = self else { return  UITableViewCell()}
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "ArcadeBetSummaryByDateCell", cellType: BetSummaryByDateCell.self)
            return cell.configure(element)
        }.disposed(by: disposeBag)
        
        rx.sentMessage(#selector(UIViewController.viewWillAppear(_:)))
            .map { _ in () }
            .bind(to: viewModel.recordByDatePagination.refreshTrigger)
            .disposed(by: disposeBag)

        tableView.rx_reachedBottom
            .map{ _ in ()}
            .bind(to: self.viewModel.recordByDatePagination.loadNextPageTrigger)
            .disposed(by: disposeBag)
        
        tableView.rx.modelSelected(GameGroupedRecord.self).bind{ [unowned self] (data) in
            self.viewModel.selectedRecord = data
            self.performSegue(withIdentifier: ArcadeBetDetailViewController.segueIdentifier, sender: nil)
        }.disposed(by: disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ArcadeBetDetailViewController.segueIdentifier {
            if let dest = segue.destination as? ArcadeBetDetailViewController {
                dest.viewModel = self.viewModel
            }
        }
    }
}
