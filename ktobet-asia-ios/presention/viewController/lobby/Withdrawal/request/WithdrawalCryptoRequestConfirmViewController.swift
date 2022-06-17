import UIKit
import RxSwift
import RxCocoa
import SharedBu

protocol NotifyRateChanged: AnyObject {
    func rateDidChange()
}

class WithdrawalCryptoRequestConfirmViewController: LobbyViewController {
    static let segueIdentifier = "toWithdrawalCryptoRequestConfirm"
    var source: RequestConfirm?
    weak var delegate: NotifyRateChanged?

    @IBOutlet weak var cryptoAmoutLabel: UILabel!
    @IBOutlet weak var cryptoAddressLabel: UILabel!
    @IBOutlet weak var fiatAmountLabel: UILabel!
    @IBOutlet weak var exchangeRateLabel: UILabel!
    @IBOutlet weak var dailyCountLabel: UILabel!
    @IBOutlet weak var dailyAmountLabel: UILabel!
    @IBOutlet weak var remainingRequirementLabel: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    
    private var request: RequestConfirm!
    private var requestCryptoAmount: CryptoCurrency {
        viewModel.cryptoDecimalToCryptoCurrency(request.supportCryptoType, request.cryptoAmount)
    }
    private var requestFlatAmount: AccountCurrency {
        viewModel.fiatDecimalToAccountCurrency(request.fiatAmount)
    }
    var viewModel: WithdrawalCryptoRequestViewModel!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        guard let source = source else {
            fatalError("\(type(of: self)) need \(type(of: RequestConfirm.self)) source.")
        }
        self.request = source
        initUI()
        dataBinding()
    }
    
    private func initUI() {
        cryptoAmoutLabel.text = requestCryptoAmount.description() + " \(requestCryptoAmount.simpleName)"
        fiatAmountLabel.text = requestFlatAmount.description() + " \(requestFlatAmount.simpleName)"
        let accountCurrency = 1.toCryptoCurrency(request.supportCryptoType) * request.exchangeRate
        exchangeRateLabel.text = "1 \(request.supportCryptoType.name)" + " = \(accountCurrency.denomination())"
        viewModel.getWithdrawalLimitation().subscribe(onSuccess: { [weak self] (limits) in
            guard let `self` = self else {return}
            self.dailyCountLabel.text = Localize.string("common_times_count", "\(limits.dailyCurrentCount - 1)")
            let fiatAccountCurrency = self.viewModel.fiatDecimalToAccountCurrency(self.request.fiatAmount)
            let remainingAmount = limits.dailyCurrentCash - fiatAccountCurrency
            self.dailyAmountLabel.text = remainingAmount.formatString(sign: .none)
            let remainingCryptoRequest = limits.calculateRemainTurnOver(depositAmount: fiatAccountCurrency)
            self.remainingRequirementLabel.text =  remainingCryptoRequest.description() + " \(remainingCryptoRequest.simpleName)"
        }, onError: { [weak self] (error) in
            self?.handleErrors(error)
        }).disposed(by: disposeBag)
        viewModel.getCryptoRequestBankCard(bankCardId: self.request.cardId).subscribe(onSuccess: { [weak self] (bank) in
            if let bank = bank {
                self?.cryptoAddressLabel.text = "\(bank.cryptoNetwork.name) - \(bank.walletAddress)"
            } else {
                self?.cryptoAddressLabel.text = ""
            }
        }, onError: { [weak self] (error) in
            self?.handleErrors(error)
        }).disposed(by: disposeBag)
    }
    
    private func dataBinding() {
        submitButton.rx.touchUpInside
            .debounce(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
            .bind(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.viewModel.requestCryptoWithdrawal(playerCryptoBankCardId: self.request.cardId, requestCryptoAmount: self.request.cryptoAmount.doubleValue, requestFiatAmount: self.request.fiatAmount.doubleValue, cryptoCurrency: self.requestCryptoAmount).subscribe(onCompleted: { [weak self] in
                    self?.popThenToast()
                }, onError: { [weak self] (error) in
                    self?.handleErrors(error)
                }).disposed(by: self.disposeBag)
            }).disposed(by: disposeBag)
    }
    
    private func popThenToast() {
        NavigationManagement.sharedInstance.popToRootViewController({
            if let topVc = UIApplication.shared.windows.filter({ $0.isKeyWindow }).first?.topViewController {
                let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: topVc.view.frame.width, height: 48))
                toastView.show(on: topVc.view, statusTip: Localize.string("common_request_submitted"), img: UIImage(named: "Success"))
            }
        })
    }
    
    override func handleErrors(_ error: Error) {
        switch error {
        case is KtoRequestCryptoRateChange:
            self.delegate?.rateDidChange()
            self.notifyRateChanged()
        case is KtoPlayerWithdrawalDefective:
            notifyRequestFailureThenExit()
        case is KtoPlayerNotQualifiedForCryptoWithdrawal:
            alertPlayerNotQualifiedForCryptoWithdrawal()
        default:
            super.handleErrors(error)
        }
    }
    
    private func notifyRateChanged() {
        displayAlert(Localize.string("cps_rate_changed"), Localize.string("cps_please_refill_amounts"))
    }
    
    private func notifyRequestFailureThenExit() {
        displayAlert(nil, Localize.string("withdrawal_fail"))
    }
    
    private func alertPlayerNotQualifiedForCryptoWithdrawal() {
        Alert.show(nil, Localize.string("cps_withdrawal_all_fiat_first"), confirm: {}, cancel: nil)
    }
    
    private func displayAlert(_ title: String?, _ message: String) {
        Alert.show(title, message, confirm: {
            NavigationManagement.sharedInstance.back()
        }, cancel: nil)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

struct RequestConfirm {
    let cardId: String
    let supportCryptoType: SupportCryptoType
    let cryptoAmount: Decimal
    let fiatCurrency: AccountCurrency
    let fiatAmount: Decimal
    let exchangeRate: IExchangeRate
}
