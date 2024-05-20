import RxSwift
import sharedbu
import SwiftUI
import UIKit

class WithdrawalLogSummaryViewController:
    LobbyViewController,
    SwiftUIConverter
{
    @Injected var viewModel: WithdrawalLogSummaryViewModel

    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
}

// MARK: - UI

extension WithdrawalLogSummaryViewController {
    private func setupUI() {
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)

        addSubView(
            from: { [unowned self] in
                SafeAreaReader {
                    WithdrawalLogSummaryView(
                        viewModel: self.viewModel,
                        dateFilterAction: .init(
                            onDateSelected: {
                                self.viewModel.dateType = $0
                            },
                            onPresentController: {
                                self.presentDateViewController($0)
                            }),
                        onPresentFilterController: {
                            self.presentFilterViewController()
                        },
                        onRowSelected: {
                            self.navigateToWithdrawalRecordDetail(log: $0)
                        })
                }
                .environment(\.playerLocale, viewModel.getSupportLocale())
            },
            to: view)
    }

    private func binding() {
        viewModel.errors()
            .subscribe(onNext: { [weak self] in
                self?.handleErrors($0)
            })
            .disposed(by: disposeBag)
    }

    private func presentDateViewController(_ didSelected: ((DateType) -> Void)?) {
        present(
            DateViewController
                .instantiate(
                    type: viewModel.dateType,
                    didSelected: didSelected)
                .embedToNavigation(),
            animated: true)
    }

    private func presentFilterViewController() {
        present(
            FilterViewController(
                presenter: viewModel,
                haveSelectAll: false,
                selectAtLeastOne: true,
                allowMultipleSelection: true,
                onDone: nil)
                .embedToNavigation(),
            animated: true)
    }

    private func navigateToWithdrawalRecordDetail(log: WithdrawalDto.Log) {
        let detailMainViewController = WithdrawalRecordDetailMainViewController(
            displayId: log.displayId,
            paymentCurrencyType: log.type)

        navigationController?.pushViewController(detailMainViewController, animated: true)
    }
}
