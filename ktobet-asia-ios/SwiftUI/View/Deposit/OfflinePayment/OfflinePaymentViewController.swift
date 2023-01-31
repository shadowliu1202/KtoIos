import Foundation
import RxSwift
import SharedBu

class OfflinePaymentViewController:
    LobbyViewController, SwiftUIConverter {
    
    @Injected private var viewModel: OfflinePaymentViewModel
    
    private let alert: AlertProtocol = Injectable.resolve(AlertProtocol.self)!
    private let disposeBag = DisposeBag()
    
    var offlineConfirmUnwindSegueId = "unwindToDeposit"
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    init(viewModel: OfflinePaymentViewModel) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        binding()
    }
}

// MARK: - UI

private extension OfflinePaymentViewController {
    
    func setupUI() {
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, action: #selector(back))
        
        addSubView(from: { [unowned self] in
            OfflinePaymentView(
                viewModel: viewModel,
                submitRemittanceOnClick: { (memoDTO, bankCardDTO) in
                    self.navigateToOfflineConfirmVC(memoDTO, bankCardDTO)
                }
            )
        }, to: view)
    }
    
    func binding() {
        viewModel.errors()
            .subscribe(onNext: { [weak self] in
                self?.handleErrors($0)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Navigation

extension OfflinePaymentViewController {
    
    @objc func back() {
        alert.show(
            Localize.string("common_confirm_cancel_operation"),
            Localize.string("deposit_offline_termniate"),
            confirm: { NavigationManagement.sharedInstance.popViewController() },
            cancel: { }
        )
    }

    private func navigateToOfflineConfirmVC(_ memoDTO: OfflineDepositDTO.Memo, _ bankCardDTO: PaymentsDTO.BankCard) {
        let vc = DepositOfflineConfirmViewController
            .instantiate(memo: memoDTO, selectedBank: bankCardDTO, unwindSegueId: offlineConfirmUnwindSegueId)
        
        navigationController?.pushViewController(vc, animated: true)
    }
}
