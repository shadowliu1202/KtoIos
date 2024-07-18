import RxSwift
import sharedbu
import UIKit

class WithdrawalCryptoWalletsViewController:
    LobbyViewController,
    SwiftUIConverter
{
    @Injected private var alert: AlertProtocol
    @Injected private var viewModel: WithdrawalCryptoWalletsViewModel

    private let disposeBag = DisposeBag()

    init(
        viewModel: WithdrawalCryptoWalletsViewModel? = nil,
        alert: AlertProtocol? = nil
    ) {
        if let viewModel {
            _viewModel.wrappedValue = viewModel
        }

        if let alert {
            _alert.wrappedValue = alert
        }

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
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

extension WithdrawalCryptoWalletsViewController {
    private func setupUI() {
        NavigationManagement.sharedInstance.addBarButtonItem(
            vc: self,
            barItemType: .back,
            action: #selector(tapBack)
        )

        addSubView(
            from: { [unowned self] in
                WithdrawalCryptoWalletsView(
                    viewModel: viewModel,
                    toAddWallet: { [weak self] in
                        self?.navigationController?
                            .pushViewController(
                                WithdrawalCreateCryptoAccountViewController(),
                                animated: true
                            )
                    },
                    toBack: {
                        NavigationManagement.sharedInstance.popViewController()
                    },
                    onUpToMaximum: {
                        self.popMaximumAlert()
                    },
                    onWalletSelected: {
                        self.handleWalletSelect($0, isEditing: $1)
                    }
                )
            },
            to: view
        )
    }

    private func binding() {
        viewModel.errors()
            .subscribe(onNext: { [weak self] error in
                self?.handleErrors(error)
            })
            .disposed(by: disposeBag)
    }

    @objc
    private func tapBack() {
        if viewModel.isEditing {
            viewModel.isEditing = !viewModel.isEditing
        } else {
            NavigationManagement.sharedInstance.popViewController()
        }
    }

    func handleWalletSelect(_ wallet: WithdrawalDto.CryptoWallet, isEditing: Bool) {
        if isEditing {
            navigateToWalletDetail(wallet)
            return
        }

        guard isVerified(wallet) else {
            notifyWalletEnteringVerifyFlow(wallet)
            return
        }

        if viewModel.isValidWallet(wallet: wallet) {
            navigateToRequestFlow(wallet)
        } else {
            notifyInvalidWalletCurrency()
        }
    }

    func isVerified(_ wallet: WithdrawalDto.CryptoWallet) -> Bool {
        wallet.verifyStatus == .onHold || wallet.verifyStatus == .verified
    }

    func notifyWalletEnteringVerifyFlow(_ wallet: WithdrawalDto.CryptoWallet) {
        alert.show(
            Localize.string("profile_safety_verification_title"),
            Localize.string("cps_security_alert"),
            confirm: { [weak self] in
                self?.navigationController?
                    .pushViewController(WithdrawalOTPVerifyMethodSelectViewController(bankCardID: wallet.walletId), animated: true)
            },
            cancel: nil
        )
    }

    func notifyInvalidWalletCurrency() {
        alert.show(
            Localize.string("common_kindly_remind"),
            Localize.string("withdrawal_not_supported_crypto"),
            confirm: nil,
            cancel: nil
        )
    }

    func navigateToWalletDetail(_ wallet: WithdrawalDto.CryptoWallet) {
        navigationController?.pushViewController(WithdrawalCryptoWalletDetailViewController(wallet: wallet), animated: true)
    }

    func navigateToRequestFlow(_ wallet: WithdrawalDto.CryptoWallet) {
        navigationController?.pushViewController(WithdrawalCryptoRequestStep1ViewController(wallet: wallet), animated: true)
    }

    func popMaximumAlert() {
        alert.show(
            Localize.string("common_kindly_remind"),
            Localize.string("withdrawal_bankcard_add_overlimit", "\(viewModel.playerWallet?.maxAmount ?? 5)"),
            confirm: nil,
            cancel: nil
        )
    }
}
