import RxSwift
import sharedbu
import UIKit

class WithdrawalCryptoRequestStep1ViewController:
    LobbyViewController,
    SwiftUIConverter
{
    @Injected private var alert: AlertProtocol
    @Injected private var viewModel: WithdrawalCryptoRequestStep1ViewModel

    private let wallet: WithdrawalDto.CryptoWallet
    private let disposeBag = DisposeBag()

    init(
        viewModel: WithdrawalCryptoRequestStep1ViewModel? = nil,
        alert: AlertProtocol? = nil,
        wallet: WithdrawalDto.CryptoWallet)
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

extension WithdrawalCryptoRequestStep1ViewController {
    private func setupUI() {
        NavigationManagement.sharedInstance
            .addBarButtonItem(
                vc: self,
                barItemType: .back,
                action: #selector(tapBack))

        addSubView(
            from: { [unowned self] in
                WithdrawalCryptoRequestStep1View(
                    viewModel: self.viewModel,
                    cryptoWallet: self.wallet,
                    tapAutoFill: {
                        self.tapAutoFill(recipe: $0)
                    },
                    tapSubmit: { confirmInfo in
                        guard let confirmInfo else { return }
                        self.navigationController?
                            .pushViewController(
                                WithdrawalCryptoRequestStep2ViewController(
                                    model: confirmInfo,
                                    delegate: self),
                                animated: true)
                    })
                    .environment(\.playerLocale, viewModel.supportLocale)
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
        view.endEditing(true)
        alert.show(
            Localize.string("withdrawal_cancel_title"),
            Localize.string("withdrawal_cancel_content"),
            confirm: {
                NavigationManagement.sharedInstance.back()
            },
            confirmText: Localize.string("common_yes"),
            cancel: { },
            cancelText: Localize.string("common_no"))
    }

    func tapAutoFill(recipe: WithdrawalDto.FulfillmentRecipe) {
        switch recipe.type {
        case .notAllowedByTurnOver:
            viewModel.fillAmounts(
                accountCurrency: recipe.from,
                cryptoAmount: recipe.to)
        case .allBalance:
            viewModel.fillAmounts(
                accountCurrency: recipe.from,
                cryptoAmount: recipe.to)
        case .completeTurnOver:
            viewModel.fillAmounts(
                accountCurrency: recipe.from,
                cryptoAmount: recipe.to)
        case .oneOffMaximum:
            alertAutoFillMessage(
                title: Localize.string("common_tip_title_warm"),
                message: Localize.string("cps_auto_fill_maximum_limit"))
            { [weak self] in
                self?.viewModel.fillAmounts(
                    accountCurrency: recipe.from,
                    cryptoAmount: recipe.to)
            }
        case .dailyMaximum:
            alertAutoFillMessage(
                title: Localize.string("common_tip_title_warm"),
                message: Localize.string("cps_auto_fill_daily_limit_maximum"))
            { [weak self] in
                self?.viewModel.fillAmounts(
                    accountCurrency: recipe.from,
                    cryptoAmount: recipe.to)
            }
        case .oneOffMaximumForTurnOver:
            alertAutoFillMessage(
                title: Localize.string("common_tip_title_warm"),
                message: Localize.string("cps_auto_fill_crypto_maximum_limit"))
            { [weak self] in
                self?.viewModel.fillAmounts(
                    accountCurrency: recipe.from,
                    cryptoAmount: recipe.to)
            }
        case .dailyMaximumForTurnOver:
            alertAutoFillMessage(
                title: Localize.string("common_tip_title_warm"),
                message: Localize.string("cps_auto_fill_crypto_daily_limit_maximum"))
            { [weak self] in
                self?.viewModel.fillAmounts(
                    accountCurrency: recipe.from,
                    cryptoAmount: recipe.to)
            }
        case .remainBalanceForLimitation:
            alertAutoFillMessage(
                title: Localize.string("cps_auto_fill_not_enough_balance"),
                message: Localize.string("cps_auto_fill_remaining_balance"))
            { [weak self] in
                self?.viewModel.fillAmounts(
                    accountCurrency: recipe.from,
                    cryptoAmount: recipe.to)
            }
        }
    }

    private func alertAutoFillMessage(title: String, message: String, confirm: (() -> Void)?) {
        alert.show(
            title,
            message,
            confirm: confirm,
            confirmText: Localize.string("common_determine"),
            cancel: nil)
    }
}

// MARK: - NotifyRateChanged

extension WithdrawalCryptoRequestStep1ViewController: NotifyRateChanged {
    func rateDidChange() {
        viewModel.inputFiatAmount = ""
        viewModel.inputCryptoAmount = ""
    }
}
