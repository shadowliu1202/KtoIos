import UIKit
import share_bu
import RxSwift
import RxCocoa

protocol AccountAddComplete: class {
    func addAccountSuccess()
}

class WithdrawlAccountsViewController: UIViewController {
    let MAX_ACCOUNT_COUNT = 3
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerImg: UIImageView!
    @IBOutlet weak var footerLabel: UILabel!
    @IBOutlet weak var footerBtn: UIButton!
    var withdrawalAccounts: [WithdrawalAccount]? {
        didSet {
            self.source.accept(withdrawalAccounts ?? [])
        }
    }
    private lazy var source = BehaviorRelay<[WithdrawalAccount]>(value: [])
    private lazy var isEditMode = false {
        didSet {
            self.tableView.reloadData()
            self.updateUI()
        }
    }
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        dataBinding()
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    private func initUI() {
        tableView.separatorColor = UIColor.clear
        tableView.addBorderBottom(size: 1, color: UIColor.dividerCapeCodGray2)
        tableView.addBorderTop(size: 1, color: UIColor.dividerCapeCodGray2)
    }
    
    private func dataBinding() {
        source.asObservable().bind(to: tableView.rx.items) { [unowned self] tableView, row, item in
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
    
    private func switchToAccountDetail(_ account: WithdrawalAccount) {
        self.performSegue(withIdentifier: WithdrawalAccountDetailViewController.segueIdentifier, sender: account)
    }
    
    func tapBack() {
        if isEditMode {
            self.isEditMode.toggle()
        } else {
            NavigationManagement.sharedInstance.popViewController()
        }
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
        self.bankNumLabel.text = item.accountNumber
        self.verifyLabel.textColor = item.verifyStatusColor
        self.verifyLabel.text = item.verifyStatusLocalize
        self.imgView.isHidden = isEditMode
        return self
    }
}
