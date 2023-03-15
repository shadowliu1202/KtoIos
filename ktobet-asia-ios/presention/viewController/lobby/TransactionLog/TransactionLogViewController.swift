import RxDataSources
import RxGesture
import RxSwift
import SharedBu
import UIKit

class TransactionLogViewController: LobbyViewController,
  SwiftUIConverter
{
  @Injected private var playerConfig: PlayerConfiguration
  @Injected private var viewModel: TransactionLogViewModel

  private lazy var flowCoordinator = TranscationFlowController(self, disposeBag: disposeBag)

  private let disposeBag = DisposeBag()

  init?(
    coder: NSCoder,
    playerConfig: PlayerConfiguration,
    viewModel: TransactionLogViewModel)
  {
    super.init(coder: coder)
    self.playerConfig = playerConfig
    self.viewModel = viewModel
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    setupUI()
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

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}

// MARK: - UI

extension TransactionLogViewController {
  private func setupUI() {
    NavigationManagement.sharedInstance.addMenuToBarButtonItem(
      vc: self,
      title: Localize.string("balancelog_title"))

    flowCoordinator.delegate = self

    addSubView(
      from: { [unowned self] in
        SafeAreaReader {
          TransactionLogView(
            viewModel: self.viewModel,
            playerConfig: self.playerConfig,
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
        }
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
}

// MARK: - TranscationFlowDelegate

extension TransactionLogViewController: TranscationFlowDelegate {
  func displaySportsBookDetail(wagerId: String) {
    viewModel
      .getSportsBookWagerDetail(wagerId: wagerId)
      .subscribe(onSuccess: { [weak self] html in
        let controller = TransactionHtmlViewController.initFrom(storyboard: "TransactionLog")
        controller.html = html
        controller.view.backgroundColor = UIColor.black131313.withAlphaComponent(0.8)
        controller.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        controller.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        self?.present(controller, animated: true, completion: nil)
      })
      .disposed(by: disposeBag)
  }
}
