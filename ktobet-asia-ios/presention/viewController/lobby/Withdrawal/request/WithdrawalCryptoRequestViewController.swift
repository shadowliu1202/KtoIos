import UIKit
import RxSwift
import RxCocoa
import SharedBu

class WithdrawalCryptoRequestViewController: APPViewController, NotifyRateChanged {
    static let segueIdentifier = "toWithdrawalCryptoRequest"
    var bankcardId: String?
    var supportCryptoType: SupportCryptoType!
    var cryptoNewrok: CryptoNetwork!
    @IBOutlet private weak var withdrawalStep1TitleLabel: UILabel!
    @IBOutlet private weak var withdrawalTitleLabel: UILabel!
    @IBOutlet weak var exchangeRateView: ExchangeRateView!
    @IBOutlet weak var exchangeInput: ExchangeInputStack!
    private weak var cryptoView: CryptoView!
    private weak var fiatView: FiatView!
    @IBOutlet private weak var withdrawalAmountErrorLabel: UILabel!
    @IBOutlet private weak var withdrawalLimitLabel: UILabel!
    @IBOutlet private weak var autoFillButton: UIButton!
    @IBOutlet private weak var nextButton: UIButton!
    
    private var cryptoType: SupportCryptoType!
    private lazy var fiat = viewModel.localCurrency
    
    fileprivate var viewModel = DI.resolve(WithdrawalCryptoRequestViewModel.self)!
    private var disposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, action: #selector(tapBack))
        guard let _ = bankcardId else {
            fatalError("\(type(of: self)) need cardId.")
        }
        guard let source = supportCryptoType else {
            fatalError("\(type(of: self)) need supportCryptoType.")
        }
        self.cryptoType = source
        initUI()
    }
    
    @objc func tapBack() {
        view.endEditing(true)
        Alert.show(Localize.string("withdrawal_cancel_title"), Localize.string("withdrawal_cancel_content"), confirm: {
            NavigationManagement.sharedInstance.back()
        }, confirmText: Localize.string("common_yes"), cancel: {}, cancelText: Localize.string("common_no"))
    }
    
    private func initUI() {
        cryptoView = exchangeInput.cryptoView
        fiatView = exchangeInput.fiatView
        let stream = self.rx.viewWillAppear.flatMap({ [unowned self](_) in
            return Observable.combineLatest(viewModel.getCryptoWithdrawalLimits(cryptoType, cryptoNewrok).asObservable(),
                                            viewModel.getBalance().asObservable(), viewModel.cryptoCurrency(cryptoCurrency: cryptoType).asObservable())
        }).share()
        setupExchangeUI(stream)
        setupWithdrawalAmountRange(stream)
        setupAutoFillAmount(stream)
        dataBinding(stream)
    }
    
    private func setupExchangeUI(_ stream: Observable<(WithdrawalLimits, AccountCurrency, IExchangeRate)>) {
        stream.subscribe(onNext: { [weak self] (_, _, cryptoExchangeRate) in
            guard let `self` = self else {return}
            self.exchangeRateView.setup(self.cryptoType, cryptoExchangeRate, self.fiat, self.cryptoNewrok.name)
            self.exchangeInput.setup(self.cryptoType, 0.toCryptoCurrency(self.cryptoType), self.fiat, exchangeRate: cryptoExchangeRate)
        }, onError: { [weak self] (error) in
            self?.handleErrors(error)
        }).disposed(by: disposeBag)
    }
    
    private func setupWithdrawalAmountRange(_ stream: Observable<(WithdrawalLimits, AccountCurrency, IExchangeRate)>) {
        stream.subscribe(onNext: { [weak self] (limits, _, _) in
            guard let `self` = self else {return}
            let minimum = limits.singleCashMinimum.description()
            let maximum = limits.singleCashMaximum.description()
            self.withdrawalLimitLabel.text = Localize.string("withdrawal_amount_range", minimum, maximum)
        }, onError: { [weak self] (error) in
            self?.handleErrors(error)
        }).disposed(by: disposeBag)
    }
    
    private func setupAutoFillAmount(_ stream: Observable<(WithdrawalLimits, AccountCurrency, IExchangeRate)>) {
        stream.subscribe(onNext: { [weak self] (limits, balance, currency) in
            let title = limits.hasCryptoRequirement() ? Localize.string("cps_auto_fill_request") : Localize.string("cps_auto_fill_balance")
            self?.autoFillButton.setTitle(title, for: .normal)
        }, onError: { [weak self] (error) in
            self?.handleErrors(error)
        }).disposed(by: disposeBag)
        
        self.autoFillButton.rx.touchUpInside.withLatestFrom(stream).bind(onNext: { [weak self] (withdrawalLimits, balance, cryptoExchangeRate) in
            self?.autoFillAmount(limits: withdrawalLimits, balance: balance, rate: cryptoExchangeRate)
        }).disposed(by: disposeBag)
    }
    
    private func autoFillAmount(limits: WithdrawalLimits, balance: AccountCurrency, rate: IExchangeRate) {
        if (limits.hasCryptoRequirement()) {
            let cryptoTurnover = limits.unresolvedCryptoTurnover
            switch verifyWithdrawalAmount(limits, cryptoTurnover) {
            case .Valid:
                filledCryptoRequestByBalance(cryptoTurnover: cryptoTurnover, limits: limits, balance: balance, rate: rate)
            case .NotAllowed:
                fillAmounts(accountCurrency: "0.0".toAccountCurrency(), cryptoAmount: "0.0".toCryptoCurrency(supportCryptoType: cryptoType))
            case .AboveLimitation:
                filledCryptoRequesByLimit(limits: limits, balance: balance, rate: rate)
            }
        } else {
            switch verifyWithdrawalAmount(limits, balance) {
            case .Valid, .NotAllowed:
                fillAmounts(accountCurrency: balance, rate: rate)
            case .AboveLimitation:
                filledAmountByLimit(limits: limits, balance: balance, rate: rate)
            }
        }
    }
    
    private enum AmountVerifyStatus {
        case Valid
        case NotAllowed
        case AboveLimitation
    }

    private func verifyWithdrawalAmount(_ limits: WithdrawalLimits, _ cryptoTurnover: AccountCurrency) -> AmountVerifyStatus {
        if cryptoTurnover < limits.singleCashMinimum {
            return .NotAllowed
        } else if limits.maxSingleWithdrawAmount() < cryptoTurnover {
            return .AboveLimitation
        } else {
            return .Valid
        }
    }
    
    private func filledCryptoRequestByBalance(cryptoTurnover: AccountCurrency, limits: WithdrawalLimits, balance: AccountCurrency, rate: IExchangeRate) {
        if balance > cryptoTurnover {
            fillAmounts(accountCurrency: cryptoTurnover, cryptoAmount: limits.unresolvedCryptoTurnover * rate)
        } else {
            alertBalanceNotEnoughAndFillRemaining(balance: balance, rate: rate)
        }
    }
    
    private func filledCryptoRequesByLimit(limits: WithdrawalLimits, balance: AccountCurrency, rate: IExchangeRate) {
        if limits.maxSingleWithdrawAmount() > balance {
            alertBalanceNotEnoughAndFillRemaining(balance: balance, rate: rate)
        } else if limits.dailyMaxCash > limits.singleCashMaximum {
            alertAutoFillMessage(title: Localize.string("common_tip_title_warm"), message: Localize.string("cps_auto_fill_crypto_maximum_limit")) {
                self.fillAmounts(accountCurrency: limits.singleCashMaximum, cryptoAmount: limits.singleCashMaximum * rate)
            }
        } else if limits.dailyMaxCash < limits.singleCashMaximum {
            alertAutoFillMessage(title: Localize.string("common_tip_title_warm"), message: Localize.string("cps_auto_fill_crypto_daily_limit_maximum")) {
                self.fillAmounts(accountCurrency: limits.dailyMaxCash, cryptoAmount: limits.dailyMaxCash * rate)
            }
        }
    }
    
    private func filledAmountByLimit(limits: WithdrawalLimits, balance: AccountCurrency, rate: IExchangeRate) {
        if limits.maxSingleWithdrawAmount() > balance {
            alertBalanceNotEnoughAndFillRemaining(balance: balance, rate: rate)
        } else if limits.dailyMaxCash > limits.singleCashMaximum {
            alertAutoFillMessage(title: Localize.string("common_tip_title_warm"), message: Localize.string("cps_auto_fill_maximum_limit")) {
                self.fillAmounts(accountCurrency: limits.singleCashMaximum, cryptoAmount: limits.singleCashMaximum * rate)
            }
        } else if limits.dailyMaxCash < limits.singleCashMaximum {
            alertAutoFillMessage(title: Localize.string("common_tip_title_warm"), message: Localize.string("cps_auto_fill_daily_limit_maximum")) {
                self.fillAmounts(accountCurrency: limits.dailyMaxCash, cryptoAmount: limits.dailyMaxCash * rate)
            }
        }
    }
    
    private func alertBalanceNotEnoughAndFillRemaining(balance: AccountCurrency, rate: IExchangeRate) {
        alertAutoFillMessage(title: Localize.string("cps_auto_fill_not_enough_balance"), message: Localize.string("cps_auto_fill_remaining_balance")) {
            self.fillAmounts(accountCurrency: balance, cryptoAmount: balance * rate)
        }
    }
    
    private func alertAutoFillMessage(title: String, message: String, confirm: (() -> Void)? ) {
        Alert.show(title, message, confirm: confirm, confirmText: Localize.string("common_determine"), cancel: nil)
    }
    
    private func fillAmounts(accountCurrency: AccountCurrency, rate: IExchangeRate) {
        fillAmounts(accountCurrency: accountCurrency, cryptoAmount: accountCurrency * rate)
    }
    
    private func fillAmounts(accountCurrency: AccountCurrency, cryptoAmount: CryptoCurrency) {
        cryptoView.setAmount(cryptoAmount.description())
        fiatView.setAmount(accountCurrency.description())
    }
    
    private func dataBinding(_ stream: Observable<(WithdrawalLimits, AccountCurrency, IExchangeRate)>) {
        exchangeInput.text.subscribe(onNext: { [weak self] (cryptoAmountStr, fiatAmountStr)  in
            if let cryptoAmountStr = cryptoAmountStr, let cryptoAmount = cryptoAmountStr.currencyAmountToDeciemal() {
                self?.viewModel.inputCryptoAmount = cryptoAmount
            }
            if let fiatAmountStr = fiatAmountStr, let fiatAmount = fiatAmountStr.currencyAmountToDeciemal() {
                self?.viewModel.inputFiatAmount = fiatAmount
            }
        }).disposed(by: disposeBag)
        
        viewModel.withdrawalAmountValidation().bind(onNext: { [weak self] (error: WithdrawalCryptoRequestViewModel.ValidError) in
            var errorMsg: String?
            switch error {
            case .none:
                errorMsg = nil
            case .amountBeyondRange:
                errorMsg = Localize.string("withdrawal_amount_beyond_range")
            case .amountBelowRange:
                errorMsg = Localize.string("withdrawal_amount_below_range")
            case .amountExceedDailyLimit:
                errorMsg = Localize.string("withdrawal_amount_exceed_daily_limit")
            case .notEnoughBalance:
                errorMsg = Localize.string("withdrawal_balance_not_enough")
            }
            self?.exchangeInput.setError(errorMsg)
        }).disposed(by: disposeBag)
        
        viewModel.withdrawalValidation.bind(to: nextButton.rx.isValid).disposed(by: disposeBag)
        
        nextButton.rx.touchUpInside.withLatestFrom(stream).bind(onNext: { [weak self] (_, _, cryptoExchangeRate) in
            guard let `self` = self else {return}
            let request = RequestConfirm(cardId: self.bankcardId!, supportCryptoType: self.cryptoType, cryptoAmount: self.viewModel.inputCryptoAmount, fiatCurrency: self.fiat, fiatAmount: self.viewModel.inputFiatAmount, exchangeRate: cryptoExchangeRate)
            self.performSegue(withIdentifier: WithdrawalCryptoRequestConfirmViewController.segueIdentifier, sender: request)
        }).disposed(by: disposeBag)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WithdrawalCryptoRequestConfirmViewController.segueIdentifier {
            if let dest = segue.destination as? WithdrawalCryptoRequestConfirmViewController {
                dest.source = sender as? RequestConfirm
                dest.delegate = self
                dest.viewModel = self.viewModel
            }
        }
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    // MARK: NotifyRateChanged
    func rateDidChange() {
        cryptoView.clearAmount()
        fiatView.clearAmount()
        nextButton.isValid = false
    }
}

class ExchangeRateView: UIView {
    @IBOutlet private weak var cryptoIcon: UIImageView!
    @IBOutlet private weak var cryptoLabel: UILabel!
    @IBOutlet private weak var networkNameLabel: UILabel!
    @IBOutlet private weak var exchangeRateLabel: UILabel!
    @IBOutlet private weak var exchangeLabel: UILabel!
    private var cryptoType: SupportCryptoType!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setup(_ cryptoType: SupportCryptoType, _ cryptoExchangeRate: IExchangeRate, _ fiatCurrency: AccountCurrency, _ cryptoNetworkName: String) {
        cryptoLabel.text = cryptoType.name
        cryptoIcon.image = cryptoType.icon
        exchangeRateLabel.text = cryptoExchangeRate.formatString()
        exchangeLabel.text = "1 \(cryptoType.name)" + " = \(cryptoExchangeRate.formatString())" + " \(fiatCurrency.simpleName)"
        networkNameLabel.text = cryptoNetworkName
    }
    
}

class CurrencyView: UIView {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet private weak var currencyLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textField.setRightPaddingPoints(16)
    }
    
    func setup(_ currency: CryptoUIResource) {
        imageView.image = currency.flagIcon
        currencyLabel.text = currency.name
    }
    
    func setFocus(_ isFocus: Bool) {
        if isFocus {
            textField.textColor = UIColor.whiteFull
        } else {
            textField.textColor = UIColor.textPrimaryDustyGray
        }
    }
    
    func setAmount(_ text: String) {
        let str = text.replacingOccurrences(of: ",", with: "")
        guard var amount = str.currencyAmountToDeciemal() else {return}
        let maxmumAmount: Decimal = 9999999
        if amount > maxmumAmount {
            amount = maxmumAmount
            textField.text = amount.currencyFormatWithoutSymbol()
        } else if str.contains(".") {
            textField.text = text
        } else {
            textField.text = currencyFormat(amount)
        }
        textField.sendActions(for: .valueChanged)
    }
    
    func clearAmount() {
        textField.text?.removeAll()
        textField.sendActions(for: .valueChanged)
    }
    
    func currencyFormat(_ amount: Decimal) -> String {
        fatalError("implements in subclass")
    }
}

class CryptoView: CurrencyView {
    override func currencyFormat(_ amount: Decimal) -> String {
        return amount.currencyFormatWithoutSymbol(precision: 0, maximumFractionDigits: 8)
    }
}

class FiatView: CurrencyView {
    override func currencyFormat(_ amount: Decimal) -> String {
        return amount.currencyFormatWithoutSymbol(precision: 0, maximumFractionDigits: 2)
    }
}

class ExchangeInputStack: UIStackView, UITextFieldDelegate {
    @IBOutlet private weak var contenView: UIView!
    @IBOutlet weak var cryptoView: CryptoView!
    @IBOutlet weak var fiatView: FiatView!
    @IBOutlet private weak var errorLabel: UILabel!
    var exchangeRate: IExchangeRate!
    private var cryptoType: SupportCryptoType!
    
    var text : Observable<(ControlProperty<String?>.Element, ControlProperty<String?>.Element)>{
        get {
            return Observable.combineLatest(cryptoView.textField.rx.text, fiatView.textField.rx.text)
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cryptoView.textField.delegate = self
        cryptoView.textField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        fiatView.textField.delegate = self
        fiatView.textField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
    }

    func setup(_ cryptoType: SupportCryptoType, _ currency: CryptoUIResource..., exchangeRate: IExchangeRate) {
        self.cryptoType = cryptoType
        cryptoView.setup(currency[0])
        fiatView.setup(currency[1])
        self.exchangeRate = exchangeRate
    }
    
    func setError(_ errMsg: String?) {
        contenView.bordersColor = errMsg == nil ? UIColor.textPrimaryDustyGray : UIColor.alert
        errorLabel.text = errMsg
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == cryptoView.textField {
            cryptoView.setFocus(true)
            fiatView.setFocus(false)
        } else {
            cryptoView.setFocus(false)
            fiatView.setFocus(true)
        }
    }
    
    @objc private func textFieldEditingChanged(_ textField: UITextField) {
        guard let str = textField.text, var amount = str.currencyAmountToDeciemal() else {
            cryptoView.textField.text = "0"
            fiatView.textField.text = "0"
            cryptoView.textField.sendActions(for: .valueChanged)
            fiatView.textField.sendActions(for: .valueChanged)
            return
        }
        let maxmumAmount: Decimal = 9999999
        if amount > maxmumAmount {
            amount = maxmumAmount
        }
        
        if textField == cryptoView.textField {
            cryptoView.setAmount(str)
            let cryptoAmount = amount.toCryptoCurrency(cryptoType)
            let fiatAmount = cryptoAmount * exchangeRate
            fiatView.setAmount(fiatAmount.description())
        } else if textField == fiatView.textField {
            fiatView.setAmount(str)
            if let doubleAmount = fiatView.currencyFormat(amount).currencyAmountToDeciemal()?.doubleValue {
                let crptoAmount = (doubleAmount.toAccountCurrency() * exchangeRate).description()
                cryptoView.setAmount(crptoAmount)
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let str = textField.text, str.contains(".") {
            if str.hasSuffix(".") {
                textField.text = String(str.dropLast())
                textField.sendActions(for: .valueChanged)
            } else {
                if textField.superview is CurrencyView, let amount = str.currencyAmountToDeciemal() {
                    textField.text = (textField.superview as! CurrencyView).currencyFormat(amount)
                    textField.sendActions(for: .valueChanged)
                }
            }
        }
    }
    
}
