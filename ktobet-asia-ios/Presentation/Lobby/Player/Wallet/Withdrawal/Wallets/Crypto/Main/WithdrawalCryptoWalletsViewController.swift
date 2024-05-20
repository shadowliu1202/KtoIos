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
        alert: AlertProtocol? = nil)
    {
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

extension WithdrawalCryptoWalletsViewController {
    private func setupUI() {
        NavigationManagement.sharedInstance.addBarButtonItem(
            vc: self,
            barItemType: .back,
            action: #selector(tapBack))

        addSubView(
            from: { [unowned self] in
                WithdrawalCryptoWalletsView(
                    viewModel: self.viewModel,
                    toAddWallet: { [weak self] in
                        self?.navigationController?
                            .pushViewController(
                                WithdrawalCreateCryptoAccountViewController(),
                                animated: true)
                    },
                    toBack: {
                        NavigationManagement.sharedInstance.popViewController()
                    },
                    onUpToMaximum: {
                        self.popMaximumAlert()
                    },
                    onWalletSelected: {
                        self.handleWalletSelect($0, isEditing: $1)
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

    @objc
    private func tapBack() {
        if viewModel.isEditing {
            viewModel.isEditing = !viewModel.isEditing
        }
        else {
            NavigationManagement.sharedInstance.popViewController()
        }
    }

    func handleWalletSelect(_ wallet: WithdrawalDto.CryptoWallet, isEditing: Bool) {
        if isEditing {
            self.navigationController?
                .pushViewController(
                    WithdrawalCryptoWalletDetailViewController(wallet: wallet),
                    animated: true)
        }
        else {
            if
                wallet.verifyStatus == .onHold ||
                wallet.verifyStatus == .verified
            {
                self.navigationController?
                    .pushViewController(
                        WithdrawalCryptoRequestStep1ViewController(wallet: wallet),
                        animated: true)
            }
            else {
                alert.show(
                    Localize.string("profile_safety_verification_title"),
                    Localize.string("cps_security_alert"),
                    confirm: { [weak self] in
                        self?.navigationController?
                            .pushViewController(
                                WithdrawalOTPVerifyMethodSelectViewController(bankCardID: wallet.walletId),
                                animated: true)
                    },
                    cancel: nil)
            }
        }
    }

    func popMaximumAlert() {
        alert.show(
            Localize.string("common_kindly_remind"),
            Localize.string("withdrawal_bankcard_add_overlimit", "\(viewModel.playerWallet?.maxAmount ?? 5)"),
            confirm: nil,
            cancel: nil)
    }
}
