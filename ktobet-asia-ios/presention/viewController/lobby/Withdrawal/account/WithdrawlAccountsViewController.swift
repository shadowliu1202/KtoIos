import UIKit
import SharedBu
import RxSwift
import RxCocoa

protocol AccountAddComplete: class {
    func addAccountSuccess()
}

class WithdrawlAccountsViewController: UIViewController {
    static let unwindSegue = "unwindsegueAccount"
    let MAX_ACCOUNT_COUNT = 3
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
    var withdrawalAccounts: [WithdrawalAccount]? {
        didSet {
            if withdrawalAccounts == nil {
                self.isEditMode = false
            }
            self.source.accept(withdrawalAccounts ?? [])
        }
    }
    private lazy var source = BehaviorRelay<[WithdrawalAccount]>(value: [])
    private lazy var cryptoSource = BehaviorRelay<[CryptoBankCard]>(value: [])
    private lazy var isEditMode = false {
        didSet {
            self.tableView.reloadData()
            self.updateUI()
        }
    }
    fileprivate var bankCardViewModel = DI.resolve(ManageCryptoBankCardViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        initUI()
        dataBinding()
        updateUI()
    }
    
    private func initUI() {
        tableView.separatorColor = UIColor.clear
        tableView.addBorderBottom(size: 1, color: UIColor.dividerCapeCodGray2)
        tableView.addBorderTop(size: 1, color: UIColor.dividerCapeCodGray2)
    }
    
    private func dataBinding() {
        switch bankCardType {
        case .general:
            generalDataBinding()
        case .crypto:
            cryptoDataBinding()
        default:
            break
        }
    }
    
    private func cryptoDataBinding() {
        let cryptoDataSource = self.rx.viewWillAppear.flatMap({ [unowned self](_) in
            return self.bankCardViewModel.getCryptoBankCards().asObservable()
        }).share(replay: 1)
        cryptoDataSource.subscribe {[weak self] (cryptoBankCards) in
            self?.cryptoSource.accept(cryptoBankCards)
        }.disposed(by: disposeBag)
        cryptoDataSource.asObservable().bind(to: tableView.rx.items) { [unowned self] tableView, row, item in
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
        footerBtn.rx.touchUpInside
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                if self.isEditMode {
                    switch self.bankCardType {
                    case .general:
                        self.switchToAddAccount()
                    case .crypto:
                        self.switchToAddCryptoAccount()
                    default:
                        break
                    }
                } else {
                    self.isEditMode.toggle()
                }
            }).disposed(by: disposeBag)
    }
    
    private func generalDataBinding() {
        let dataSource = self.rx.viewWillAppear.flatMap({ [unowned self](_) in
            return source.asObservable()
        }).share(replay: 1)
        dataSource.asObservable().bind(to: tableView.rx.items) { [unowned self] tableView, row, item in
            return tableView.dequeueReusableCell(withIdentifier: "AccountCell", cellType: AccountCell.self).configure(item, self.isEditMode)
        }.disposed(by: disposeBag)
        tableView.rx.modelSelected(WithdrawalAccount.self).bind{ [unowned self] (data) in
            if self.isEditMode {
                self.switchToAccountDetail(data)
            } else {
                self.performSegue(withIdentifier: WithdrawalRequestViewController.segueIdentifier, sender: data)
            }
        }.disposed(by: disposeBag)
        footerBtn.rx.touchUpInside
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                if self.isEditMode {
                    self.switchToAddAccount()
                } else {
                    self.isEditMode.toggle()
                }
            }).disposed(by: disposeBag)
    }
    
    private func updateUI() {
        if isEditMode {
            titleLabel.text = Localize.string("withdrawal_setaccount")
            footerImg.image = UIImage(named: "Add")
            footerLabel.text = Localize.string("withdrawal_setbankaccount_button")
        } else {
            titleLabel.text = Localize.string("withdrawal_selectbankcard")
            footerImg.image = UIImage(named: "Default(32)")
            footerLabel.text = Localize.string("withdrawal_setaccount")
        }
    }
    
    private func switchToAddAccount() {
        if self.withdrawalAccounts?.count ?? 0 < MAX_ACCOUNT_COUNT {
            self.performSegue(withIdentifier: AddBankViewController.segueIdentifier, sender: nil)
        } else {
            let title = Localize.string("common_kindly_remind")
            let msg = Localize.string("withdrawal_bankcard_add_overlimit", "\(MAX_ACCOUNT_COUNT)")
            Alert.show(title, msg, confirm: nil, cancel: nil)
        }
    }
    
    private func switchToAddCryptoAccount() {
        if cryptoSource.value.count >= MAX_ACCOUNT_COUNT {
            Alert.show(Localize.string("common_tip_title_warm"),  String(format: Localize.string("withdrawal_bankcard_add_overlimit"), "3"), confirm: nil, cancel: nil, tintColor: UIColor.red)
        } else {
            self.performSegue(withIdentifier: AddCryptoAccountViewController.segueIdentifier, sender: cryptoSource.value.count)
        }
    }
    
    private func switchToAccountDetail(_ account: WithdrawalAccount) {
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
                dest.account = sender as? WithdrawalAccount
            }
        }
        
        if segue.identifier == WithdrawalRequestViewController.segueIdentifier {
            if let dest = segue.destination as? WithdrawalRequestViewController {
                dest.account = sender as? WithdrawalAccount
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
                dest.bankCardCount = cryptoSource.value.count
            }
        }
        
        if segue.identifier == WithdrawalCryptoRequestViewController.segueIdentifier {
            if let dest = segue.destination as? WithdrawalCryptoRequestViewController {
                if let bankCard = sender as? CryptoBankCard {
                    dest.bankcardId = bankCard.id_
                    dest.cryptoCurrency = bankCard.currency
                    
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
    
    func configure(_ item: WithdrawalAccount, _ isEditMode: Bool) -> Self {
        self.selectionStyle = .none
        self.bankNameLabel.text = item.bankName
        self.bankNumLabel.text = item.accountNumber.value
        self.verifyLabel.textColor = item.verifyStatusColor
        self.verifyLabel.text = item.verifyStatusLocalize
        self.imgView.isHidden = isEditMode
        return self
    }
}


class CryptoAccountCell: UITableViewCell {
    @IBOutlet weak var bankNameLabel: UILabel!
    @IBOutlet weak var walletType: UILabel!
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
        return self
    }
}
