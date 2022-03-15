import UIKit
import SharedBu
import RxSwift
import RxCocoa

protocol AccountAddComplete: AnyObject {
    func addAccountSuccess()
}

class WithdrawlAccountsViewController: APPViewController {
    static let unwindSegue = "unwindsegueAccount"
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerImg: UIImageView!
    @IBOutlet weak var footerLabel: UILabel!
    @IBOutlet weak var footerBtn: UIButton!
    var bankCardType: BankCardType!
    var cryptoBankCards: [CryptoBankCard]? {
        didSet {
            if cryptoBankCards == nil {
                self.isEditMode = false
            }
            self.cryptoSource.accept(cryptoBankCards ?? [])
        }
    }
    var withdrawalAccounts: [FiatBankCard]? {
        didSet {
            if withdrawalAccounts == nil {
                self.isEditMode = false
            }
            self.source.accept(withdrawalAccounts ?? [])
        }
    }
    private lazy var source = BehaviorRelay<[FiatBankCard]>(value: [])
    private lazy var cryptoSource = BehaviorRelay<[CryptoBankCard]>(value: [])
    lazy var isEditMode = false {
        didSet {
            self.tableView.reloadData()
            self.updateUI()
        }
    }
    fileprivate var bankCardViewModel = DI.resolve(ManageCryptoBankCardViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    fileprivate var switchAddAccount: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        initUI()
        dataBinding()
        updateUI()
    }
    
    private func initUI() {
        tableView.separatorColor = UIColor.clear
        tableView.addTopBorder(size: 0.5, color: UIColor.dividerCapeCodGray2)
    }
    
    private func dataBinding() {
        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        switch bankCardType {
        case .general:
            generalDataBinding()
            switchAddAccount = switchToAddAccount
        case .crypto:
            cryptoDataBinding()
            switchAddAccount = switchToAddCryptoAccount
        default:
            break
        }
        
        footerBtn.rx.touchUpInside
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                if self.isEditMode {
                    self.switchAddAccount?()
                } else {
                    self.isEditMode.toggle()
                }
            }).disposed(by: disposeBag)
    }
    
    private func cryptoDataBinding() {
        let cryptoDataSource = self.rx.viewWillAppear.flatMap({ [unowned self](_) in
            return cryptoSource.asObservable()
        }).share(replay: 1)
        cryptoDataSource.asObservable()
            .catchError({ [weak self] (error) -> Observable<[CryptoBankCard]> in
                self?.handleErrors(error)
                return Observable.just([])
            }).bind(to: tableView.rx.items) { [unowned self] tableView, row, item in
            return tableView.dequeueReusableCell(withIdentifier: "CryptoAccountCell", cellType: CryptoAccountCell.self).configure(item, self.isEditMode)
        }.disposed(by: disposeBag)
        tableView.rx.modelSelected(CryptoBankCard.self).bind{ [unowned self] (data) in
            if self.isEditMode {
                self.switchToCryptoAccountDetail(data)
            } else {
                if data.bankCard.verifyStatus == PlayerBankCardVerifyStatus.verified {
                    self.performSegue(withIdentifier: WithdrawalCryptoRequestViewController.segueIdentifier, sender: data)
                } else {
                    Alert.show(Localize.string("profile_safety_verification_title"), Localize.string("cps_security_alert"), confirm: {
                        self.performSegue(withIdentifier: WithdrawalCryptoVerifyViewController.segueIdentifier, sender: data)
                    }, cancel: nil)
                }
            }
        }.disposed(by: disposeBag)
    }
    
    private func generalDataBinding() {
        let dataSource = self.rx.viewWillAppear.flatMap({ [unowned self](_) in
            return source.asObservable()
        }).share(replay: 1)
        dataSource.asObservable()
            .catchError({ [weak self] (error) -> Observable<[FiatBankCard]> in
                self?.handleErrors(error)
                return Observable.just([])
            }).bind(to: tableView.rx.items) { [unowned self] tableView, row, item in
            return tableView.dequeueReusableCell(withIdentifier: "AccountCell", cellType: AccountCell.self).configure(item, self.isEditMode)
        }.disposed(by: disposeBag)
        tableView.rx.modelSelected(FiatBankCard.self).bind{ [unowned self] (data) in
            if self.isEditMode {
                self.switchToAccountDetail(data)
            } else {
                self.performSegue(withIdentifier: WithdrawalRequestViewController.segueIdentifier, sender: data)
            }
        }.disposed(by: disposeBag)
    }
    
    private func updateUI() {
        if isEditMode {
            titleLabel.text = Localize.string("withdrawal_accountsetting_title")
            footerImg.image = UIImage(named: "Add")
            footerLabel.text = Localize.string("withdrawal_setbankaccount_button")
        } else {
            titleLabel.text = Localize.string("withdrawal_selectbankcard")
            footerImg.image = UIImage(named: "Default(32)")
            footerLabel.text = Localize.string("withdrawal_setaccount")
        }
    }
    
    private func switchToAddAccount() {
        if self.withdrawalAccounts?.count ?? 0 < Settings.init().WITHDRAWAL_CASH_BANK_CARD_LIMIT {
            self.performSegue(withIdentifier: AddBankViewController.segueIdentifier, sender: nil)
        } else {
            let title = Localize.string("common_kindly_remind")
            let msg = Localize.string("withdrawal_bankcard_add_overlimit", "\(Settings.init().WITHDRAWAL_CASH_BANK_CARD_LIMIT)")
            Alert.show(title, msg, confirm: nil, cancel: nil)
        }
    }
    
    private func switchToAddCryptoAccount() {
        if cryptoSource.value.count >= Settings.init().WITHDRAWAL_CRYPTO_BANK_CARD_LIMIT {
            Alert.show(Localize.string("common_tip_title_warm"),  String(format: Localize.string("withdrawal_bankcard_add_overlimit"), "\(Settings.init().WITHDRAWAL_CRYPTO_BANK_CARD_LIMIT)"), confirm: nil, cancel: nil, tintColor: UIColor.red)
        } else {
            self.performSegue(withIdentifier: AddCryptoAccountViewController.segueIdentifier, sender: cryptoSource.value.count)
        }
    }
    
    private func switchToAccountDetail(_ account: FiatBankCard) {
        self.performSegue(withIdentifier: WithdrawalAccountDetailViewController.segueIdentifier, sender: account)
    }
    
    private func switchToCryptoAccountDetail(_ account: CryptoBankCard) {
        self.performSegue(withIdentifier: CryptoAccountDetailViewController.segueIdentifier, sender: account)
    }
    
    func tapBack() {
        if isEditMode {
            self.isEditMode.toggle()
        } else {
            NavigationManagement.sharedInstance.popViewController()
        }
    }
    
    @IBAction func unwindSegueAccount(segue: UIStoryboardSegue) {
        NavigationManagement.sharedInstance.viewController = self
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
}

extension WithdrawlAccountsViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == WithdrawalAccountDetailViewController.segueIdentifier {
            if let dest = segue.destination as? WithdrawalAccountDetailViewController {
                dest.account = sender as? FiatBankCard
            }
        }
        
        if segue.identifier == WithdrawalRequestViewController.segueIdentifier {
            if let dest = segue.destination as? WithdrawalRequestViewController {
                dest.account = sender as? FiatBankCard
            }
        }
        
        if segue.identifier == AddBankViewController.segueIdentifier {
            if let dest = segue.destination as? AddBankViewController {
                dest.delegate = self
            }
        }
        
        if segue.identifier == AddCryptoAccountViewController.segueIdentifier {
            if let dest = segue.destination as? AddCryptoAccountViewController {
                dest.bankCardCount = sender as? Int ?? 0
            }
        }
        
        if segue.identifier == WithdrawalCryptoVerifyViewController.segueIdentifier {
            if let dest = segue.destination as? WithdrawalCryptoVerifyViewController {
                dest.cryptoBankCard = sender as? CryptoBankCard
            }
        }
        
        if segue.identifier == WithdrawalCryptoRequestViewController.segueIdentifier {
            if let dest = segue.destination as? WithdrawalCryptoRequestViewController {
                if let bankCard = sender as? CryptoBankCard {
                    dest.bankcardId = bankCard.id_
                    dest.supportCryptoType = bankCard.currency
                    dest.cryptoNewrok = bankCard.cryptoNetwork
                }
            }
        }
        
        if segue.identifier == CryptoAccountDetailViewController.segueIdentifier {
            if let dest = segue.destination as? CryptoAccountDetailViewController {
                dest.account = sender as? CryptoBankCard
            }
        }
    }
}

extension WithdrawlAccountsViewController: AccountAddComplete {
    func addAccountSuccess() {
        self.isEditMode = false
    }
}

extension WithdrawlAccountsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110.5
    }
}

class AccountCell: UITableViewCell {
    @IBOutlet weak var bankNameLabel: UILabel!
    @IBOutlet weak var bankNumLabel: UILabel!
    @IBOutlet weak var verifyLabel: UILabel!
    @IBOutlet weak var imgView: UIImageView!
    private lazy var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    func configure(_ item: FiatBankCard, _ isEditMode: Bool) -> Self {
        self.selectionStyle = .none
        self.bankNameLabel.text = item.bankCard.name
        self.bankNumLabel.text = item.accountNumber
        self.verifyLabel.textColor = item.verifyStatusColor
        self.verifyLabel.text = item.verifyStatusLocalize
        self.imgView.isHidden = isEditMode
        return self
    }
}


class CryptoAccountCell: UITableViewCell {
    @IBOutlet weak var bankNameLabel: UILabel!
    @IBOutlet weak var walletType: UILabel!
    @IBOutlet weak var networkLabel: UILabel!
    @IBOutlet weak var bankNumLabel: UILabel!
    @IBOutlet weak var verifyLabel: UILabel!
    @IBOutlet weak var imgView: UIImageView!
    private lazy var disposeBag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    func configure(_ item: CryptoBankCard, _ isEditMode: Bool) -> Self {
        let verifyStatus = StringMapper.sharedInstance.getVerifyStatus(status: item.verifyStatus)
        self.selectionStyle = .none
        self.bankNameLabel.text = item.name
        self.bankNumLabel.text = item.walletAddress
        self.verifyLabel.textColor = verifyStatus.color
        self.verifyLabel.text = verifyStatus.text
        self.imgView.isHidden = isEditMode
        self.walletType.text = item.currency.name
        self.networkLabel.text = item.cryptoNetwork.name
        return self
    }
}
