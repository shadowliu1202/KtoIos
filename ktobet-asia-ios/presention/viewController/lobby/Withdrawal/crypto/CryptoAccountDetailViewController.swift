import UIKit
import RxSwift
import SharedBu


class CryptoAccountDetailViewController: LobbyViewController {
    static let segueIdentifier = "toCryptoAccountDetail"
    
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var verifyStatusLabel: UILabel!
    @IBOutlet weak var accountNameLabel: UILabel!
    @IBOutlet weak var cryptoTypeLabel: UILabel!
    @IBOutlet weak var cryptoNetworkLabel: UILabel!
    @IBOutlet weak var accountNumberLabel: UILabel!
    
    var account: CryptoBankCard!

    fileprivate var viewModel = Injectable.resolve(ManageCryptoBankCardViewModel.self)!
    fileprivate var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
        
        verifyStatusLabel.text = StringMapper.getVerifyStatus(status: account.verifyStatus).text
        accountNameLabel.text = account.name
        cryptoTypeLabel.text = account.currency.name
        cryptoNetworkLabel.text = account.cryptoNetwork.name
        accountNumberLabel.text = account.walletAddress
        
        deleteButton.isHidden = account.verifyStatus == .onhold ? true : false
        deleteButton.rx.tap.subscribe(onNext: {[weak self] in
            guard let self = self else { return }
            if self.account.verifyStatus == PlayerBankCardVerifyStatus.verified {
                self.alertVerifiedDelete()
            } else {
                self.alertDelete()
            }
        }).disposed(by: disposeBag)
    }
    
    private func alertDelete() {
        Alert.shared.show(Localize.string("withdrawal_bankcard_delete_confirm_title"), Localize.string("withdrawal_bankcard_delete_confirm_content"), confirm: {
            self.deleteAccount()
        }, cancel: { }, tintColor: UIColor.redF20000)
    }
    
    private func alertVerifiedDelete() {
        Alert.shared.show(Localize.string("withdrawal_bankcard_delete_confirm_title"), Localize.string("cps_crypto_delete_hint"), confirm: {
            self.deleteAccount()
        }, cancel: { }, tintColor: UIColor.redF20000)
    }
    
    private func deleteAccount() {
        self.viewModel.deleteCryptoAccount(account.id_).subscribe(onCompleted: {
            self.viewModel.getCryptoBankCards().map{ $0.count }.subscribe{(count) in
                if count == 0 {
                    if let vc = UIStoryboard(name: "Withdrawal", bundle: nil).instantiateViewController(withIdentifier: "WithdrawlEmptyViewController") as? WithdrawlEmptyViewController {
                        vc.bankCardType = .crypto
                        NavigationManagement.sharedInstance.pushViewController(vc: vc)
                    }
                } else {
                    NavigationManagement.sharedInstance.popViewController()
                }
            } onError: {[weak self] (error) in
                self?.handleErrors(error)
            }.disposed(by: self.disposeBag)
        }, onError: {[weak self] (error) in
            self?.handleErrors(error)
        }).disposed(by: self.disposeBag)
    }
}
