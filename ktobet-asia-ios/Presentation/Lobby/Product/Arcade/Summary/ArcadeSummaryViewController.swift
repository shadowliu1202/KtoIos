import RxDataSources
import RxSwift
import sharedbu
import UIKit

class ArcadeSummaryViewController: LobbyViewController {
    @IBOutlet private var tableView: UITableView!

    private var emptyStateView: EmptyStateView!

    private var viewModel = Injectable.resolve(ArcadeRecordViewModel.self)!
    private var disposeBag = DisposeBag()
    private var unfinishGameCount: Int32 = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(
            vc: self,
            barItemType: .back,
            title: Localize.string("product_my_bet")
        )
        initUI()
        bindingSummaryData()
        summaryDataHandler()
    }

    private func initUI() {
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        tableView.setHeaderFooterDivider()

        initEmptyStateView()
    }

    private func initEmptyStateView() {
        emptyStateView = EmptyStateView(
            icon: UIImage(named: "No Records"),
            description: Localize.string("product_none_my_bet_record"),
            keyboardAppearance: .impossible
        )

        view.addSubview(emptyStateView)

        emptyStateView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bindingSummaryData() {
        rx.viewWillAppear.flatMap { [unowned self] _ in viewModel.getBetSummary().asObservable() }
            .share(replay: 1)
            .catch { [weak self] error -> Observable<BetSummary> in
                self?.handleErrors(error)
                return Observable.empty()
            }
            .do(onNext: { [weak self] data in
                self?.unfinishGameCount = data.unFinishedGames
                self?.switchContent(data)
            })
            .map { summary -> [DateSummary] in
                
                summary.finishedGame
            }
            .bind(to: tableView.rx.items) { [weak self] tableView, row, element in
                guard let self else { return UITableViewCell() }

                if unfinishGameCount != 0, row == 0 {
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: "unFinishGameTableViewCell",
                        cellType: UnFinishGameTableViewCell.self
                    )
                    cell.recordCountLabel.text = Localize.string("product_count_bet_record", "\(unfinishGameCount)")
                    cell.removeBorder()
                    if row != 0 {
                        cell.addBorder()
                    }

                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(
                        withIdentifier: "MyBetSummaryTableViewCell",
                        cellType: MyBetSummaryTableViewCell.self
                    )
                    .config(
                        element: .init(
                            count: Int(element.count),
                            createdDateTime: element.createdDateTime.toDateFormatString(),
                            totalStakes: element.totalStakes,
                            totalWinLoss: element.totalWinLoss
                        )
                    )

                    cell.removeBorder()
                    if row != 0 {
                        cell.addBorder()
                    }

                    return cell
                }
            }.disposed(by: disposeBag)
    }

    private func switchContent(_ summary: BetSummary? = nil) {
        if let items = summary, hasGameRecords(summary: items) {
            tableView.isHidden = false
            emptyStateView.isHidden = true
        } else {
            tableView.isHidden = true
            emptyStateView.isHidden = false
        }
    }

    private func summaryDataHandler() {
        Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(DateSummary.self))
            .bind { [weak self] indexPath, data in
                if indexPath.row == 0, self?.unfinishGameCount != 0 {
                    self?.performSegue(withIdentifier: ArcadeUnsettleRecordsViewController.segueIdentifier, sender: nil)
                }else {
                    self?.viewModel.selectedLocalDate = data.createdDateTime.toDateFormatString()
                    self?.performSegue(withIdentifier: ArcadeBetSummaryByDateViewController.segueIdentifier, sender: nil)
                }
            }.disposed(by: disposeBag)
    }

    private func hasGameRecords(summary: BetSummary) -> Bool {
        summary.finishedGame.count != 0
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        if segue.identifier == ArcadeBetSummaryByDateViewController.segueIdentifier {
            if let dest = segue.destination as? ArcadeBetSummaryByDateViewController {
                dest.viewModel = viewModel
            }
        }
    }
}

extension ArcadeSummaryViewController: UITableViewDelegate {
    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.row == 0 && unfinishGameCount != 0 ? 57 : 81
    }
}
