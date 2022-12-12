import UIKit
import RxSwift
import RxDataSources
import SharedBu
import RxGesture

class TransactionLogViewController: LobbyViewController,
                                    SwiftUIConverter {
    
    @Injected private var viewModel: TransactionLogViewModel
    private let presenter = TransactionLogPresenter()
    
    private lazy var flowCoordinator = TranscationFlowController(self, disposeBag: disposeBag)

    private let disposeBag = DisposeBag()
    
    init?(coder: NSCoder, viewModel: TransactionLogViewModel) {
        super.init(coder: coder)
        self.viewModel = viewModel
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
                Localize.string("balancelog_wager_detail_is_maintain")
            )
            
        case is PlayerWagerDetailNotFound:
            Alert.shared.show(
                Localize.string("common_notification"),
                Localize.string("balancelog_wager_sync_unfinished")
            )
            
        default:
            super.handleErrors(error)
        }
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

// MARK: - UI

private extension TransactionLogViewController {
    
    func setupUI() {
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(
            vc: self,
            title: Localize.string("balancelog_title")
        )
        
        flowCoordinator.delegate = self
        
        addSubView(
            from: { [unowned self] in
                SafeAreaReader {
                    TransactionLogView(
                        viewModel: self.viewModel,
                        presenter: self.presenter,
                        onDateSelected: { type in
                            self.viewModel.dateType = type
                            self.refresh()
                        },
                        onTypeSelected: {
                            self.viewModel.updateTypeFilter(
                                with: $0,
                                and: self.presenter
                            )
                            self.refresh()
                        },
                        onSummarySelected: {
                            self.performSegue(
                                withIdentifier: TransactionLogSummaryViewController.segueIdentifier,
                                sender: nil
                            )
                        },
                        onRowSelected: {
                            self.flowCoordinator.goNext($0)
                        },
                        onNavigateToFilterController: {
                            self.navigateToFilterViewController(
                                presenter: self.presenter,
                                conditionCallback: $0
                            )
                        }
                    )
                }
            },
            to: view
        )
    }
    
    func refresh() {
        viewModel.pagination.refreshTrigger.onNext(())
        viewModel.summaryRefreshTrigger.onNext(())
    }
    
    func navigateToFilterViewController(
        presenter: FilterPresentProtocol,
        conditionCallback: (([FilterItem]) -> Void)?
    ) {
        let filterController = TransactionFilterViewController.initFrom(storyboard: "Filter")
        
        filterController.presenter = presenter
        filterController.conditionCallback = conditionCallback
        
        navigationController?.pushViewController(filterController, animated: true)
    }
}

// MARK: - TranscationFlowDelegate

extension TransactionLogViewController: TranscationFlowDelegate {
    
    func displaySportsBookDetail(wagerId: String) {
        viewModel
            .getSportsBookWagerDetail(wagerId: wagerId)
            .subscribe(onSuccess: { [weak self] (html) in
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
