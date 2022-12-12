import UIKit
import RxSwift
import SwiftUI
import SharedBu

class WithdrawalViewController: LobbyViewController {
    @IBOutlet private weak var withdrawalTodayAmountLimitLabel: UILabel!
    @IBOutlet private weak var withdrawalTodayCountLimitLabel: UILabel!
    @IBOutlet private weak var turnoverRequirementLabel: UILabel!
    @IBOutlet weak var crpytoWithdrawalRequirementTextView: UITextView!
    @IBOutlet private weak var withdrawView: UIView!
    @IBOutlet private weak var withdrawLabel: UILabel!
    @IBOutlet private weak var crpytoView: UIView!
    @IBOutlet private weak var crpytoLabel: UILabel!
    @IBOutlet private weak var withdrawalRecordNoDataLabel: UILabel!
    @IBOutlet private weak var withdrawalRecordTitleLabel: UILabel!
    @IBOutlet private weak var showAllWithdrawalButton: UIButton!
    @IBOutlet private weak var withdrawalRecordTableView: UITableView!
    @IBOutlet private weak var constraintWithdrawalRecordTableHeight: NSLayoutConstraint!
    @IBOutlet private weak var chanelStackView: UIStackView!

    private var accounts: [FiatBankCard]?
    private var cryptoBankCards: [CryptoBankCard]?
    fileprivate var viewModel = Injectable.resolve(WithdrawalViewModel.self)!
    fileprivate var bandCardviewModel = Injectable.resolve(ManageCryptoBankCardViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    private var withdrawalLimits: WithdrawalLimits?
    
    private lazy var dailyLimitAmount: String = "" {
        didSet {
            self.withdrawalTodayAmountLimitLabel.text = Localize.string("withdrawal_daily_limit_widthrawal_amount", dailyLimitAmount)
        }
    }
    private lazy var dailyMaxCount: String = "" {
        didSet {
            self.withdrawalTodayCountLimitLabel.text = Localize.string("withdrawal_daily_limit_widthrawal_times", dailyMaxCount)
        }
    }
    private lazy var turnoverRequirement: AccountCurrency? = AccountCurrency.zero() {
        didSet {
            guard let turnoverRequirement = turnoverRequirement else {
                self.turnoverRequirementLabel.text = Localize.string("withdrawal_turnover_requirement")
                return
            }
            let suffix = !turnoverRequirement.isPositive ? Localize.string("common_none") : Localize.string("common_requirement", "\(turnoverRequirement.formatString())")
            self.turnoverRequirementLabel.text = Localize.string("withdrawal_turnover_requirement") + suffix
        }
    }
    private lazy var crpytoWithdrawalRequirement: AccountCurrency? = AccountCurrency.zero() {
        didSet {
            let cpsWithdrawalRequirement = Localize.string("cps_crpyto_withdrawal_requirement")
            var attribTextHolder: AttribTextHolder
            if let crpytoWithdrawalRequirement = crpytoWithdrawalRequirement, crpytoWithdrawalRequirement.isPositive {
                attribTextHolder = generateRequirementTextAttribute(requireAmount: crpytoWithdrawalRequirement.formatString(), cpsWithdrawalRequirement)
            } else {
                attribTextHolder = generateNotRequirementTextAttribute(cpsWithdrawalRequirement)
            }
            
            attribTextHolder.setTo(textView: crpytoWithdrawalRequirementTextView)
        }
    }
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: Localize.string("common_withdrawal"))
        initUI()
        withdrawalLimitationDataBinding()
        recordDataBinding()
        showAllRecordEvenhandler()
        recordDataEvenhandler()
        cryptoWithdrawlDataBinding()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    // MARK: PAGE ACTION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WithdrawlLandingViewController.segueIdentifier {
            if let dest = segue.destination as? WithdrawlLandingViewController {
                let bankCardType = sender as? BankCardType
                dest.accounts = accounts ?? []
                dest.cryptoBankCards = cryptoBankCards ?? []
                dest.bankCardType = bankCardType
            }
        } else if segue.identifier == CrpytoTransationLogViewController.segueIdentifier {
            if let dest = segue.destination as? CrpytoTransationLogViewController {
                dest.crpytoWithdrawalRequirementAmount = crpytoWithdrawalRequirementAmount()
            }
        }
    }
    
    @IBAction func backToWithdrawal(segue: UIStoryboardSegue) {
        NavigationManagement.sharedInstance.viewController = self
        if let vc = segue.source as? WithdrawalRequestConfirmViewController {
            if vc.withdrawalSuccess {
                let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 48))
                toastView.show(on: self.view, statusTip: Localize.string("common_request_submitted"), img: UIImage(named: "Success"))
            }
        }
    }
    
    // MARK: METHOD
    fileprivate func initUI() {
        self.dailyLimitAmount = ""
        self.dailyMaxCount = ""
        self.turnoverRequirement = nil
        crpytoWithdrawalRequirementTextView.textContainerInset = .zero
        crpytoWithdrawalRequirementTextView.textContainer.lineFragmentPadding = 0
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOnRequirementTextView(_:)))
        crpytoWithdrawalRequirementTextView.addGestureRecognizer(tapGesture)
        self.crpytoWithdrawalRequirement = nil
        withdrawalRecordTitleLabel.text = Localize.string("withdrawal_log")
        showAllWithdrawalButton.setTitle(Localize.string("common_show_all"), for: .normal)
        withdrawalRecordNoDataLabel.text = Localize.string("withdrawal_no_records")
        withdrawViewEnable(false)
        withdrawalRecordTableView.isHidden = true
        crpytoViewEnable(false)
        chanelStackView.addBorder(.top)
        chanelStackView.addBorder(.bottom)
    }
    
    private func generateRequirementTextAttribute(requireAmount: String, _ prefix: String) -> AttribTextHolder {
        var attribTextHolder: AttribTextHolder
        let suffix = Localize.string("common_requirement", requireAmount)
        let fullText = prefix + suffix
        attribTextHolder = AttribTextHolder(text: fullText)
            .addAttr((text: fullText, type: .color, UIColor.gray9B9B9B))
            .addAttr((text: fullText, type: .font, UIFont.init(name: "PingFangSC-Medium", size: 14)!))
            .addAttr((text: suffix, type: .color, UIColor.redF20000))
            .addAttr((text: suffix, type: .link(false), "TapRequireAmount://"))
        
        let padding = NSTextAttachment()
        padding.bounds = CGRect(x: 0, y: 0, width: 8.6, height: 0)
        attribTextHolder = attribTextHolder.addAttr((text: "", type: .attachment, value: padding))
        
        let tips = NSTextAttachment()
        tips.image = UIImage(named: "iconChevronRightRed7")
        tips.bounds = CGRect.init(x: 0, y: 0, width: 7.4, height: 12)
        attribTextHolder = attribTextHolder.addAttr((text: "", type: .attachment, value: tips))
        return attribTextHolder
    }
    
    private func generateNotRequirementTextAttribute(_ prefix: String) -> AttribTextHolder {
        var attribTextHolder: AttribTextHolder
        let suffix = Localize.string("common_none")
        let fullText = prefix + suffix
        attribTextHolder = AttribTextHolder(text: fullText)
            .addAttr((text: fullText, type: .color, UIColor.gray9B9B9B))
            .addAttr((text: fullText, type: .font, UIFont.init(name: "PingFangSC-Medium", size: 14)!))
            .addAttr((text: suffix, type: .color, UIColor.gray9B9B9B))
        
        let padding = NSTextAttachment()
        padding.bounds = CGRect(x: 0, y: 0, width: 10, height: 0)
        attribTextHolder = attribTextHolder.addAttr((text: "", type: .attachment, value: padding))
        
        let tips = NSTextAttachment()
        tips.image = UIImage(named: "Tips")
        tips.bounds = CGRect.init(x: 0, y: -5, width: 20, height: 20)
        attribTextHolder = attribTextHolder.addAttr((text: "", type: .attachment, value: tips))
        return attribTextHolder
    }
    
    @objc private func tapOnRequirementTextView(_ sender: UITapGestureRecognizer) {
        let textView = sender.view as! UITextView
        let layoutManager = textView.layoutManager
        
        var location = sender.location(in: textView)
        location.x -= textView.textContainerInset.left
        location.y -= textView.textContainerInset.top
        
        let characterIndex = layoutManager.characterIndex(for: location,
                                                          in: textView.textContainer,
                                                          fractionOfDistanceBetweenInsertionPoints: nil)
        
        if characterIndex < textView.textStorage.length {
            let link = textView.attributedText.attribute(NSAttributedString.Key.link,
                                                      at: characterIndex,
                                                      effectiveRange: nil)
            if link != nil {
                self.switchToCryptoTransationLog()
                return
            }
            let attachment = textView.attributedText.attribute(NSAttributedString.Key.attachment,
                                                               at: characterIndex,
                                                               effectiveRange: nil) as? NSTextAttachment
            guard attachment != nil else { return }
            if let amount = self.crpytoWithdrawalRequirementAmount(), amount.isPositive {
                self.switchToCryptoTransationLog()
            } else {
                Alert.shared.show(Localize.string("cps_crpyto_withdrawal_requirement_title"),
                           Localize.string("cps_crpyto_withdrawal_requirement_desc"),
                           confirm: {
                                self.dismiss(animated: true, completion: nil)
                           }, cancel: nil)
            }
        }
    }
    
    fileprivate func cryptoWithdrawlDataBinding() {
        bandCardviewModel.getCryptoBankCards().subscribe {[weak self] (cryptoBankCards) in
            self?.cryptoBankCards = cryptoBankCards
        } onError: { (error) in
            self.handleErrors(error)
        }.disposed(by: disposeBag)
    }
    
    fileprivate func withdrawViewEnable(_ enable: Bool) {
        if enable {
            self.withdrawView.alpha = 1
            let withdrawTap = UITapGestureRecognizer(target: self, action: #selector(withdrawTap(_:)))
            self.withdrawView.isUserInteractionEnabled = true
            self.withdrawView.addGestureRecognizer(withdrawTap)
        } else {
            self.withdrawView.alpha = 0.3
            self.withdrawView.isUserInteractionEnabled = false
        }
    }
    
    @objc fileprivate func withdrawTap(_ sender: UITapGestureRecognizer) {
        if let withdrawalLimits = withdrawalLimits, withdrawalLimits.hasCryptoRequirement() {
            Alert.shared.show(Localize.string("cps_cash_withdrawal_lock_title"),
                       Localize.string("cps_cash_withdrawal_lock_desc", crpytoWithdrawalRequirementAmount()?.denomination()),
                       confirm: {
                            self.dismiss(animated: true, completion: nil)
                       }, cancel: nil)
        } else {
            self.performSegue(withIdentifier: WithdrawlLandingViewController.segueIdentifier, sender: BankCardType.general)
        }
    }
    
    private func crpytoViewEnable(_ enable: Bool) {
        if enable {
            self.crpytoView.alpha = 1
            let crpytoTap = UITapGestureRecognizer(target: self, action: #selector(crpytoTap(_:)))
            self.crpytoView.isUserInteractionEnabled = true
            self.crpytoView.addGestureRecognizer(crpytoTap)
        } else {
            self.crpytoView.alpha = 0.3
            self.crpytoView.isUserInteractionEnabled = false
        }
    }
    
    @objc fileprivate func crpytoTap(_ sender: UITapGestureRecognizer) {
        bandCardviewModel.isCryptoWithdrawalValid.subscribe(onSuccess: { [weak self] in
            if $0 {
                self?.performSegue(withIdentifier: WithdrawlLandingViewController.segueIdentifier, sender: BankCardType.crypto)
            } else {
                self?.alertPlayerNotQualifiedForCryptoWithdrawal()
            }
        }, onFailure: { [weak self] in
            self?.handleErrors($0)
        }).disposed(by: disposeBag)
    }
    
    fileprivate func withdrawalLimitationDataBinding() {
        self.rx.viewWillAppear.flatMap({ [unowned self] (_) in
            return self.viewModel.withdrawalAccounts().asObservable()
        }).subscribe(onNext: { [weak self] (accounts) in
            self?.accounts = accounts
        }, onError: {[weak self] (error) in
            self?.handleErrors(error)
        }).disposed(by: disposeBag)
        self.rx.viewWillAppear.flatMap({ [unowned self] (_) in
            return self.viewModel.getWithdrawalLimitation().asObservable()
        }).subscribe(onNext: { [weak self] (withdrawalLimits) in
            guard let self = self else { return }
            self.withdrawalLimits = withdrawalLimits
            self.dailyLimitAmount = withdrawalLimits.dailyMaxCash.formatString()
            self.dailyMaxCount = "\(withdrawalLimits.dailyMaxCount)"
            self.turnoverRequirement = withdrawalLimits.remainCashTurnover()
            self.crpytoWithdrawalRequirement = self.crpytoWithdrawalRequirementAmount()
            self.checkDailyWithdrawalLimit(withdrawalLimits.dailyCurrentCash, withdrawalLimits.dailyCurrentCount)
        }, onError: { (error) in
            self.handleErrors(error)
        }).disposed(by: disposeBag)
    }
    
    @objc private func switchToCryptoTransationLog() {
        self.performSegue(withIdentifier: CrpytoTransationLogViewController.segueIdentifier, sender: nil)
    }
    
    private func crpytoWithdrawalRequirementCurrencyName() -> String {
        return self.withdrawalLimits?.unresolvedCryptoTurnover.denomination() ?? ""
    }
    
    private func crpytoWithdrawalRequirementAmount() -> AccountCurrency? {
        return self.withdrawalLimits?.unresolvedCryptoTurnover
    }
    
    private func checkDailyWithdrawalLimit(_ amount: AccountCurrency, _ count: Int32) {
        if !amount.isPositive || count <= 0 {
            self.withdrawViewEnable(false)
            self.crpytoViewEnable(false)
        } else {
            self.withdrawViewEnable(true)
            self.crpytoViewEnable(true)
        }
    }
    
    fileprivate func recordDataBinding() {
        let withdrawalRecord = self.rx.viewWillAppear.flatMap({ [unowned self](_) in
            return self.viewModel.getWithdrawalRecords().asObservable()
        }).share(replay: 1)
        withdrawalRecord.catchError({ [weak self] (error) in
            self?.handleErrors(error)
            return Observable.just([])
        }).do(onNext: { [weak self] (withdrawalRecord) in
            self?.withdrawalRecordTableView.isHidden = false
            self?.constraintWithdrawalRecordTableHeight.constant = CGFloat(withdrawalRecord.count * 80)
            self?.withdrawalRecordTableView.layoutIfNeeded()
            self?.withdrawalRecordTableView.addBottomBorder()
            self?.withdrawalRecordTableView.addTopBorder()
            if withdrawalRecord.count == 0 {
                self?.withdrawalRecordNoDataLabel.isHidden = false
                self?.withdrawalRecordTableView.isHidden = true
                self?.showAllWithdrawalButton.isHidden = true
            } else {
                self?.withdrawalRecordNoDataLabel.isHidden = true
                self?.withdrawalRecordTableView.isHidden = false
                self?.showAllWithdrawalButton.isHidden = false
            }
        }).bind(to: withdrawalRecordTableView.rx.items(cellIdentifier: String(describing: WithdrawRecordTableViewCell.self), cellType: WithdrawRecordTableViewCell.self)) {(index, data, cell) in
            cell.setUp(data: data)
        }.disposed(by: disposeBag)
    }
    
    fileprivate func showAllRecordEvenhandler() {
        showAllWithdrawalButton.rx.tap.subscribe(onNext: { [weak self] in
            self?.performSegue(withIdentifier: WithdrawalRecordViewController.segueIdentifier, sender: nil)
        }).disposed(by: disposeBag)
    }
    
    fileprivate func recordDataEvenhandler() {
        Observable.zip(withdrawalRecordTableView.rx.itemSelected, withdrawalRecordTableView.rx.modelSelected(WithdrawalRecord.self)).bind {[weak self] (indexPath, data) in
            guard let self = self else { return }
            let storyboard = UIStoryboard(name: "Withdrawal", bundle: Bundle.main)
            let vc = storyboard.instantiateViewController(withIdentifier: "WithdrawlRecordContainer") as! WithdrawlRecordContainer
            vc.displayId = data.displayId
            vc.transactionTransactionType = data.transactionTransactionType
            self.navigationController?.pushViewController(vc, animated: true)
            self.withdrawalRecordTableView.deselectRow(at: indexPath, animated: true)
        }.disposed(by: disposeBag)
    }
    
    override func handleErrors(_ error: Error) {
        switch error {
        case is KtoPlayerNotQualifiedForCryptoWithdrawal:
            alertPlayerNotQualifiedForCryptoWithdrawal()
        default:
            super.handleErrors(error)
        }
    }
    
    private func alertPlayerNotQualifiedForCryptoWithdrawal() {
        Alert.shared.show(nil, Localize.string("cps_withdrawal_all_fiat_first"), confirm: {}, cancel: nil)
    }
}


enum BankCardType: String {
    case crypto = "crypto"
    case general = "general"
}
