import UIKit
import RxCocoa
import RxSwift
import RxDataSources
import SharedBu
import SwiftUI

class DepositRecordViewController: LobbyViewController,
                                   SwiftUIConverter {
    static let segueIdentifier = "toAllRecordSegue"
    
    @Injected private var playerConfig: PlayerConfiguration
    
    @Injected var viewModel: DepositLogSummaryViewModel
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

// MARK: - UI

private extension DepositRecordViewController {
    
    func setupUI() {
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        
        addSubView(
            from: { [unowned self] in
                SafeAreaReader {
                    DepositLogSummaryView(
                        playerConfig: self.playerConfig,
                        viewModel: self.viewModel,
                        onDateSelected: { type in
                            self.viewModel.dateType = type
                            self.refresh()
                        },
                        onNavigateToFilterController: {
                            self.navigateToFilterViewController()
                        },
                        onRowSelected: {
                            self.navigateToDepositRecordDetail(log: $0)
                        }
                    )
                }
            },
            to: view
        )
    }
    
    func navigateToFilterViewController() {
        navigationController?.pushViewController(
            FilterViewController(
                presenter: viewModel,
                barItemType: .back,
                barItemImageName: "Close",
                haveSelectAll: false,
                selectAtLeastOne: true,
                allowMultipleSelection: true,
                onDone: { [unowned self] in
                    self.refresh()
                }
            ),
            animated: true
        )
    }
    
    func navigateToDepositRecordDetail(log: PaymentLogDTO.Log) {
        let storyboard = UIStoryboard(name: "Deposit", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(withIdentifier: "DepositRecordContainer") as! DepositRecordContainer
        vc.displayId = log.displayId
        vc.paymentCurrencyType = log.currencyType
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func refresh() {
        viewModel.pagination.refreshTrigger.onNext(())
        viewModel.summaryRefreshTrigger.onNext(())
    }
}
