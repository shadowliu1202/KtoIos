import RxSwift
import sharedbu
import UIKit

class TransactionLogViewController: LobbyViewController {
  @Injected private var viewModel: TransactionLogViewModel

  private lazy var flowCoordinator = TransactionFlowController(self, disposeBag: disposeBag)

  private let disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
    binding()
  }

  override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
    if segue.identifier == TransactionLogSummaryViewController.segueIdentifier {
      if let dest = segue.destination as? TransactionLogSummaryViewController {
        dest.viewModel = self.viewModel
      }
    }
  }

  override func handleErrors(_ error: Error) {
    switch error {
    case is PlayerWagerDetailUnderMaintain:
      Alert.shared.show(
        Localize.string("common_notification"),
        Localize.string("balancelog_wager_detail_is_maintain"))

    case is PlayerWagerDetailNotFound:
      Alert.shared.show(
        Localize.string("common_notification"),
        Localize.string("balancelog_wager_sync_unfinished"))

    default:
      super.handleErrors(error)
    }
  }
  
  private func setupUI() {
    NavigationManagement.sharedInstance.addMenuToBarButtonItem(
      vc: self,
      title: Localize.string("balancelog_title"))

    flowCoordinator.delegate = self

    addSubView(
      from: { [unowned self] in
        TransactionLogView(
          viewModel: self.viewModel,
          dateFilterAction: .init(
            onDateSelected: {
              self.viewModel.dateType = $0
              self.refresh()
            },
            onPresentController: {
              self.presentDateViewController($0)
            }),
          onSummarySelected: {
            self.performSegue(
              withIdentifier: TransactionLogSummaryViewController.segueIdentifier,
              sender: nil)
          },
          onRowSelected: {
            self.flowCoordinator.goNext($0)
          },
          onPresentFilterController: {
            self.presentFilterViewController()
          })
      },
      to: view)
  }

  private func refresh() {
    viewModel.pagination.refreshTrigger.onNext(())
    viewModel.summaryRefreshTrigger.onNext(())
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
        onDone: { [unowned self] in
          self.refresh()
        })
        .embedToNavigation(),
      animated: true)
  }
  
  private func binding() {
    viewModel.errors()
      .subscribe(onNext: { [unowned self] in handleErrors($0) })
      .disposed(by: disposeBag)
  }
}

// MARK: - TransactionFlowDelegate

extension TransactionLogViewController: TransactionFlowDelegate {
  func getIsCasinoWagerDetailExist(by wagerID: String) async -> Bool? {
    do {
      return try await viewModel.getIsCasinoWagerDetailExist(by: wagerID)
    }
    catch {
      handleErrors(error)
      return nil
    }
  }
  
  func getIsP2PWagerDetailExist(by wagerID: String) async -> Bool? {
    do {
      return try await viewModel.getIsP2PWagerDetailExist(by: wagerID)
    }
    catch {
      handleErrors(error)
      return nil
    }
  }
  
  func displaySportsBookDetail(wagerId: String) {
    viewModel
      .getSportsBookWagerDetail(wagerId: wagerId)
      .subscribe(onSuccess: { [weak self] html in
        let controller = TransactionHtmlViewController.initFrom(storyboard: "TransactionLog")
        controller.html = html
        self?.navigationController?.pushViewController(controller, animated: true)
      })
      .disposed(by: disposeBag)
  }
}
