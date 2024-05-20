import RxDataSources
import RxSwift
import sharedbu
import UIKit

class UnSettleViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
  
    private var emptyStateView: EmptyStateView!

    var viewModel: NumberGameRecordViewModel!
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
    
        initUI()
        summaryDataHandler()
        bindingSummaryData()
    }

    private func initUI() {
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        tableView.setHeaderFooterDivider(headerHeight: 0)
    
        initEmptyStateView()
    }

    private func initEmptyStateView() {
        emptyStateView = EmptyStateView(
            icon: UIImage(named: "No Records"),
            description: Localize.string("product_none_my_bet_record"),
            keyboardAppearance: .impossible)

        view.addSubview(emptyStateView)

        emptyStateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
  
    private func bindingSummaryData() {
        let shareUnSettle = self.rx.viewWillAppear.flatMap({ [unowned self] _ in
            self.viewModel.unSettled
        }).share()

        shareUnSettle.catch({ [weak self] error -> Observable<[NumberGameSummary.Date]> in
            self?.handleErrors(error)
            return Observable.just([])
        }).do(onNext: { [weak self] records in
            self?.switchContent(records.count)
        })
        .bind(to: tableView.rx.items) { [weak self] _, row, element in
            guard let self else { return UITableViewCell() }
            let cell = self.tableView.dequeueReusableCell(
                withIdentifier: "CasinoSummaryTableViewCell",
                cellType: CasinoSummaryTableViewCell.self)
            cell.setup(element: element)
            cell.removeBorder()
            if row != 0 {
                cell.addBorder(leftConstant: 30)
            }

            return cell
        }.disposed(by: disposeBag)
    }

    private func switchContent(_ count: Int) {
        if count != 0 {
            self.tableView.isHidden = false
            self.emptyStateView.isHidden = true
        }
        else {
            self.tableView.isHidden = true
            self.emptyStateView.isHidden = false
        }
    }

    private func summaryDataHandler() {
        Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(NumberGameSummary.Date.self))
            .bind { [weak self] _, data in
                guard let self else { return }
                let parameter = (data.betDate, NumberGameSummary.CompanionStatus.unSettled)
                self.performSegue(withIdentifier: NumberGameMyBetGameGroupedViewController.segueIdentifier, sender: parameter)
            }.disposed(by: disposeBag)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == NumberGameMyBetGameGroupedViewController.segueIdentifier {
            if let dest = segue.destination as? NumberGameMyBetGameGroupedViewController {
                let parameter = sender as! (betDate: sharedbu.LocalDate, status: NumberGameSummary.CompanionStatus)
                dest.betDate = parameter.betDate
                dest.betStatus = parameter.status
            }
        }
    }
}

extension UnSettleViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        81
    }
}
