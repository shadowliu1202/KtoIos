import RxSwift
import sharedbu
import UIKit

protocol NotifyRateChanged: AnyObject {
    func rateDidChange()
}

class WithdrawalCryptoRequestStep2ViewController:
    LobbyViewController,
    SwiftUIConverter
{
    @Injected private var alert: AlertProtocol
    @Injected private var viewModel: WithdrawalCryptoRequestStep2ViewModel

    private let model: WithdrawalCryptoRequestConfirmDataModel.SetupModel?
    private let disposeBag = DisposeBag()

    private weak var delegate: NotifyRateChanged?

    init(
        viewModel: WithdrawalCryptoRequestStep2ViewModel? = nil,
        alert: AlertProtocol? = nil,
        model: WithdrawalCryptoRequestConfirmDataModel.SetupModel,
        delegate: NotifyRateChanged)
    {
        if let viewModel {
            self._viewModel.wrappedValue = viewModel
        }

        if let alert {
            self._alert.wrappedValue = alert
        }

        self.model = model
        self.delegate = delegate

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

    override func handleErrors(_ error: Error) {
        switch error {
        case let withdrawalException as WithdrawalException:
            switch onEnum(of: withdrawalException) {
            case .exceededPaymentGroupLimit:
                alert.show(
                    Localize.string("common_tip_title_warm"),
                    Localize.string("cps_withdrawal_exceeding_daily_limit_message"),
                    confirm: { self.navigateBack() },
                    cancel: nil)
            case .playerAmountBelowLimit:
                alert.show(
                    Localize.string("common_tip_title_warm"),
                    Localize.string("cps_withdrawal_fiat_amount_below_limit_message"),
                    confirm: { self.navigateBack() },
                    cancel: nil)
            case .playerAmountExceededLimit:
                alert.show(
                    Localize.string("common_tip_title_warm"),
                    Localize.string("cps_withdrawal_fiat_amount_over_limit_message"),
                    confirm: { self.navigateBack() },
                    cancel: nil)
            case .playerNotQualified:
                alert.show(nil, Localize.string("cps_withdrawal_all_fiat_first"), confirm: { }, cancel: nil)
            case .playerWithdrawalDefective:
                alert.show(nil, Localize.string("withdrawal_fail"), confirm: { self.navigateBack() }, cancel: nil)
            case .requestCryptoRateChanged:
                self.delegate?.rateDidChange()
                alert.show(
                    Localize.string("cps_rate_changed"),
                    Localize.string("cps_please_refill_amounts"),
                    confirm: { self.navigateBack() },
                    cancel: nil)
            }
        default:
            super.handleErrors(error)
        }
    }
}

extension WithdrawalCryptoRequestStep2ViewController {
    private func setupUI() {
        NavigationManagement.sharedInstance
            .addBarButtonItem(
                vc: self,
                barItemType: .back)

        addSubView(
            from: { [unowned self] in
                WithdrawalCryptoRequestStep2View(
                    viewModel: self.viewModel,
                    model: self.model,
                    submitSuccess: {
                        NavigationManagement.sharedInstance.popToRootViewController({
                            @Injected var snackBar: SnackBar
                            snackBar.show(tip: Localize.string("common_request_submitted"), image: UIImage(named: "Success"))
                        })
                    })
                    .environment(\.playerLocale, viewModel.getSupportLocale())
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

    private func navigateBack() {
        self.navigationController?.popViewController(animated: true)
    }
}
