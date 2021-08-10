import UIKit
import RxSwift
import RxCocoa
import SharedBu

class WithdrawalCryptoRequestConfirmViewController: UIViewController {
    static let segueIdentifier = "toWithdrawalCryptoRequestConfirm"
    var source: RequestConfirm?

    @IBOutlet weak var cryptoAmoutLabel: UILabel!
    @IBOutlet weak var fiatAmountLabel: UILabel!
    @IBOutlet weak var exchangeRateLabel: UILabel!
    @IBOutlet weak var dailyCountLabel: UILabel!
    @IBOutlet weak var dailyAmountLabel: UILabel!
    @IBOutlet weak var remainingRequirementLabel: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    
    private var request: RequestConfirm!
    private var viewModel = DI.resolve(WithdrawalCryptoRequestViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        guard let source = source else {
            fatalError("\(type(of: self)) need \(type(of: RequestConfirm.self)) source.")
        }
        self.request = source
        initUI()
        dataBinding()
    }
    
    private func initUI() {
        cryptoAmoutLabel.text = request.cryptoAmount.currencyFormatWithoutSymbol(precision: 8, maximumFractionDigits: 8) + " \(request.crypto.simpleName)"
        fiatAmountLabel.text = request.fiatAmount.currencyFormatWithoutSymbol(precision: 2, maximumFractionDigits: 2) + " \(request.fiatCurrency.simpleName)"
        exchangeRateLabel.text = "1 \(request.crypto.simpleName)" + " = \(request.exchangeRate.rate.currencyFormatWithoutSymbol(precision: 2, maximumFractionDigits: 2))" + " \(request.fiatCurrency.simpleName)"
        viewModel.getWithdrawalLimitation().subscribe(onSuccess: { [weak self] (limits) in
            guard let `self` = self else {return}
            self.dailyCountLabel.text = Localize.string("common_times_count", "\(limits.dailyMaxCount - 1)")
            let remainingAmount = limits.dailyMaxCash.amount - self.request.fiatAmount.doubleValue
            self.dailyAmountLabel.text = remainingAmount.currencyFormatWithoutSymbol(precision: 2, maximumFractionDigits: 2)
            var remainingCryptoRequest = limits.unresolvedCryptoTurnover().cryptoAmount - self.request.cryptoAmount.doubleValue
            if remainingCryptoRequest < 0 {
                remainingCryptoRequest = 0
            }
            self.remainingRequirementLabel.text =  remainingCryptoRequest.currencyFormatWithoutSymbol(precision: 8, maximumFractionDigits: 8) + " \(self.request.crypto.simpleName)"
        }, onError: { [weak self] (error) in
            self?.handleErrors(error)
        }).disposed(by: disposeBag)
    }
    
    private func dataBinding() {
        submitButton.rx.touchUpInside
            .debounce(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
            .bind(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.viewModel.requestCryptoWithdrawal(playerCryptoBankCardId: self.request.cardId, requestCryptoAmount: self.request.cryptoAmount.doubleValue, requestFiatAmount: self.request.fiatAmount.doubleValue, cryptoCurrency: self.request.crypto).subscribe(onCompleted: { [weak self] in
                    self?.popThenToast()
                }, onError: { [weak self] (error) in
                    self?.handleKtoError(error)
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
    
    private func handleKtoError(_ error: Error) {
        if error is KtoRequestCryptoRateChange {
            self.notifyRateChanged()
        } else {
            handleErrors(error)
        }
    }
    
    private func notifyRateChanged() {
        Alert.show(Localize.string("cps_rate_changed"), Localize.string("cps_please_refill_amounts"), confirm: {
            NavigationManagement.sharedInstance.back()
        }, cancel: nil)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

struct RequestConfirm {
    let cardId: String
    let crypto: Crypto
    let cryptoAmount: Decimal
    let fiatCurrency: FiatCurrency
    let fiatAmount: Decimal
    let exchangeRate: CryptoExchangeRate
}
