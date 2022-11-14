import UIKit
import SharedBu
import RxSwift
import RxCocoa
import RxDataSources


class NumberGameMyBetGameGroupedViewController: LobbyViewController {
    static let segueIdentifier = "toNumberGameMyBetGameGrouped"
    
    let viewModel = Injectable.resolve(NumberGameRecordViewModel.self)!
    private var disposeBag = DisposeBag()
    
    @IBOutlet private weak var tableView: UITableView!
    
    var betDate: SharedBu.LocalDate!
    var betStatus: NumberGameSummary.CompanionStatus!
    
    fileprivate var activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, title: betDate.toBetDisplayDate())
        initUI()
        dataBinding()
        summaryDataHandler()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }

    private func initUI() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        self.tableView.setHeaderFooterDivider()
    }
    
    var tempResult: [NumberGameSummary.Game] = []
    var tempIndex: [Int] = []
    private func dataBinding() {
        viewModel.selectedDate = betDate
        viewModel.selectedStatus = betStatus
        viewModel.pagination.elements.do(onNext: {[weak self] (games) in
            guard let self = self else { return }
            self.tempIndex = []
            if !self.tempResult.isEmpty {
                let difference = self.tempResult.difference(from: games)
                difference.forEach { (game) in
                    if let index = self.tempResult.firstIndex(of: game)  {
                        self.tempIndex.append(index)
                    }
                }
            }
            
            if games.count > self.tempResult.count {
                self.tempResult = games
            }
        }).map({[weak self]  (games) -> [NumberGameSummary.Game] in
            return self?.tempResult ?? []
        }).bind(to: tableView.rx.items){[weak self] (tableView, row, element) in
            guard let self = self else { return  UITableViewCell()}
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "SlotBetSummaryByDateCell", cellType: BetSummaryByDateCell.self)
            cell.configure(element)
            if self.tempIndex.contains(row) {
                cell.iconImageView.isHidden = true
                for view in cell.contentView.subviews {
                    view.alpha = 0.4
                }
            }
            
            cell.removeBorder()
            if row != 0 {
                cell.addBorder(leftConstant: 30)
            }
            
            return cell
        }.disposed(by: disposeBag)
        
        rx.sentMessage(#selector(UIViewController.viewWillAppear(_:)))
            .map { _ in () }
            .bind(to: viewModel.pagination.refreshTrigger)
            .disposed(by: disposeBag)

        tableView.rx.reachedBottom
            .map{ _ in ()}
            .bind(to: self.viewModel.pagination.loadNextPageTrigger)
            .disposed(by: disposeBag)
        
        viewModel.pagination.loading.asObservable()
            .bind(to: isLoading(for: self.view))
            .disposed(by: disposeBag)
    }
    
    private func summaryDataHandler() {
        Observable.zip(tableView.rx.itemSelected, tableView.rx.modelSelected(NumberGameSummary.Game.self)).bind {[weak self] (indexPath, data) in
            guard let self = self else { return }
            if self.tempIndex.contains(indexPath.row) {
                Alert.shared.show(nil, Localize.string("product_bet_has_settled"), confirm: nil, cancel: nil)
            } else {
                let parameter = (data.gameId, self.betStatus, self.betDate, data.gameName)
                self.performSegue(withIdentifier: NumberGameDetailViewController.segueIdentifier, sender: parameter)
            }
        }.disposed(by: disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == NumberGameDetailViewController.segueIdentifier {
            if let dest = segue.destination as? NumberGameDetailViewController {
                let parameter = sender as! (gameId: Int32, status: NumberGameSummary.CompanionStatus, betDate: SharedBu.LocalDate, gameName: String)
                dest.betDate = parameter.betDate
                dest.betStatus = parameter.status
                dest.gameName = parameter.gameName
                dest.gameId = parameter.gameId
            }
        }
    }
    
    fileprivate func isLoading(for view: UIView) -> AnyObserver<Bool> {
        return Binder(view, binding: {[weak self] (hud, isLoading) in
            guard let self = self else { return }
            switch isLoading {
            case true:
                self.startActivityIndicator(activityIndicator: self.activityIndicator)
            case false:
                self.stopActivityIndicator(activityIndicator: self.activityIndicator)
                break
            }
        }).asObserver()
    }

}
