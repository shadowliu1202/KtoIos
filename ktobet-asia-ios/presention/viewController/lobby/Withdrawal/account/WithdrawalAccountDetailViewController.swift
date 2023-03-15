import RxSwift
import SharedBu
import UIKit

class WithdrawalAccountDetailViewController: LobbyViewController {
  static let segueIdentifier = "toAccountDetail"

  fileprivate var viewModel = Injectable.resolve(WithdrawlLandingViewModel.self)!
  fileprivate var playerViewModel = Injectable.resolve(PlayerViewModel.self)!
  fileprivate var disposeBag = DisposeBag()
  var account: FiatBankCard?
  @IBOutlet weak var verifyStatusLabel: UILabel!
  @IBOutlet weak var userNameLabel: UILabel!
  @IBOutlet weak var bankNameLabel: UILabel!
  @IBOutlet weak var branchNameLabel: UILabel!
  @IBOutlet weak var provinceLabel: UILabel!
  @IBOutlet weak var countryLabel: UILabel!
  @IBOutlet weak var accountNumberLabel: UILabel!
  @IBOutlet weak var submitButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    initUI()
    dataBinding()
  }

  private func initUI() {
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    verifyStatusLabel.text = account?.verifyStatusLocalize
    playerViewModel.loadPlayerInfo()
      .map { $0.playerInfo.withdrawalName }
      .bind(to: userNameLabel.rx.text)
      .disposed(by: disposeBag)
    userNameLabel.text = account?.accountName
    bankNameLabel.text = account?.bankCard.name
    branchNameLabel.text = account?.branch
    provinceLabel.text = account?.location
    countryLabel.text = account?.city
    accountNumberLabel.text = account?.accountNumber
    if account?.verifyStatus == .onhold {
      submitButton.isHidden = true
    }
  }

  private func dataBinding() {
    submitButton.rx.touchUpInside.bind { [weak self] _ in
      if let self, let id = self.account?.bankCard.id_ {
        Alert.shared.show(
          Localize.string("common_confirm_delete"),
          Localize.string("withdrawal_bank_card_deleting"),
          confirm: { self.deleteAccount(id) },
          confirmText: Localize.string("common_yes"),
          cancel: { },
          cancelText: Localize.string("common_no"))
      }
    }.disposed(by: disposeBag)
  }

  private func deleteAccount(_ playerBankCardId: String) {
    viewModel.deleteAccount(playerBankCardId).subscribe(onCompleted: { [weak self] in
      self?.popThenToast()
    }, onError: { [weak self] error in
      self?.handleErrors(error)
    }).disposed(by: disposeBag)
  }

  private func popThenToast() {
    NavigationManagement.sharedInstance.popViewController({
      @Injected var snackBar: SnackBar
      snackBar.show(tip: Localize.string("withdrawal_account_deleted"), image: UIImage(named: "Success"))
    })
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}
