import RxSwift
import sharedbu
import SwiftUI
import UIKit

class DepositLogSummaryViewController:
  LobbyViewController,
  SwiftUIConverter
{
  @Injected var viewModel: DepositLogSummaryViewModel

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

// MARK: - UI

extension DepositLogSummaryViewController {
  private func setupUI() {
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)

    addSubView(
      from: { [unowned self] in
        SafeAreaReader {
          DepositLogSummaryView(
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
              self.navigateToDepositRecordDetail(log: $0)
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

  private func navigateToDepositRecordDetail(log: PaymentLogDTO.Log) {
    let detailMainViewController = DepositRecordDetailMainViewController(
      displayId: log.displayId,
      paymentCurrencyType: log.currencyType)

    navigationController?.pushViewController(detailMainViewController, animated: true)
  }
}
