import RxSwift
import sharedbu
import UIKit

class WithdrawalFiatWalletDetailViewController:
    LobbyViewController,
    SwiftUIConverter
{
    @Injected private var snackBar: SnackBar
    @Injected private var alert: AlertProtocol
    @Injected private var viewModel: WithdrawalFiatWalletDetailViewModel

    private let wallet: WithdrawalDto.FiatWallet
    private let disposeBag = DisposeBag()

    init(
        viewModel: WithdrawalFiatWalletDetailViewModel? = nil,
        alert: AlertProtocol? = nil,
        wallet: WithdrawalDto.FiatWallet)
    {
        self.wallet = wallet

        if let viewModel {
            self._viewModel.wrappedValue = viewModel
        }

        if let alert {
            self._alert.wrappedValue = alert
        }

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        binding()
    }
}

// MARK: - UI

extension WithdrawalFiatWalletDetailViewController {
    private func setupUI() {
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)

        addSubView(
            from: { [unowned self] in
                WithdrawalFiatWalletDetailView(
                    viewModel: self.viewModel,
                    wallet: self.wallet,
                    onDelete: {
                        self.popDeleteConfirmAlert()
                    },
                    onDeleteSuccess: {
                        self.snackBar.show(tip: Localize.string("withdrawal_account_deleted"), image: UIImage(named: "Success"))
                        NavigationManagement.sharedInstance.popViewController()
                    })
            },
            to: view)
    }

    private func binding() {
        viewModel.errors()
            .subscribe(onNext: { [weak self] error in
                self?.handleErrors(error)
            })
            .disposed(by: disposeBag)
    }

    func popDeleteConfirmAlert() {
        alert.show(
            Localize.string("withdrawal_bankcard_delete_confirm_title"),
            Localize.string("withdrawal_bankcard_delete_confirm_content"),
            confirm: { [weak self] in
                self?.viewModel.deleteWallet()
            },
            confirmText: Localize.string("common_yes"),
            cancel: { },
            cancelText: Localize.string("common_no"))
    }
}
