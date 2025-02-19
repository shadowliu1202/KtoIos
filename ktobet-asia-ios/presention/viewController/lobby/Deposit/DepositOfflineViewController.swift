import RxSwift
import share_bu
import UIKit

class DepositMethodViewController: UIViewController {
  @IBOutlet private weak var titleLabel: UILabel!
  @IBOutlet private weak var selectDepositBankLabel: UILabel!
  @IBOutlet private weak var depositTableView: UITableView!
  @IBOutlet private weak var bankTableView: UITableView!
  @IBOutlet private weak var myDepositInfo: UILabel!
  @IBOutlet private weak var remitterBankTextField: InputText!
  @IBOutlet private weak var remitterNameTextField: InputText!
  @IBOutlet private weak var remitterBankCardNumberTextField: InputText!
  @IBOutlet private weak var remitterAmountTextField: InputText!
  @IBOutlet private weak var depositLimitLabel: UILabel!
  @IBOutlet private weak var depositConfirmButton: UIButton!
  @IBOutlet private weak var scrollView: UIScrollView!
  @IBOutlet private weak var constraintBankTableHeight: NSLayoutConstraint!
  @IBOutlet private weak var constraintAllBankTableHeight: NSLayoutConstraint!
  @IBOutlet private weak var constraintremitterBankTextFieldHeight: NSLayoutConstraint!
  @IBOutlet private weak var constraintremitterBankTextFieldTop: NSLayoutConstraint!
  @IBOutlet private weak var remitterBankErrorLabel: UILabel!
  @IBOutlet private weak var remitterNameErrorLabel: UILabel!
  @IBOutlet private weak var remitterBankCardNumberErrorLabel: UILabel!
  @IBOutlet private weak var remitterAmountErrorLabel: UILabel!

  static let segueIdentifier = "toOfflineSegue"
  var depositType: DepositRequest.DepositType?
  fileprivate var selectedIndex = 0
  fileprivate var viewModel = DI.resolve(DepositViewModel.self)!
  fileprivate var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self, isShowAlert: true)
    if depositType is DepositRequest.DepositTypeOffline {
      offlineDataBinding()
      offlineEventHandle()
      banksDataBinding()
      banksEventHandle()
      validateOfflineInputTextField()
    }

    if depositType is DepositRequest.DepositTypeThirdParty {
      remitterBankTextField.isHidden = true
      constraintremitterBankTextFieldHeight.constant = 0
      constraintremitterBankTextFieldTop.constant = 0
      thirdPartDataBinding()
      thirdPartEventHandler()
      validateOnlineInputTextField()
    }

    initUI()
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == DepositOfflineConfirmViewController.segueIdentifier {
      if let dest = segue.destination as? DepositOfflineConfirmViewController {
        var customDecimal = 0.0
        repeat {
          customDecimal = OfflineDepositCash.Companion().customDecimal()
        }
        while customDecimal.decimalCount() != 2
        let requestAmount = OfflineDepositCash(
          cashAmount: CashAmount(amount: Double(
            self.viewModel.relayBankAmount.value
              .replacingOccurrences(of: ",", with: ""))!),
          customDecimal: customDecimal)
        let depositRequest = DepositRequest
          .Builder(paymentToken: String(self.viewModel.selectedReceiveBank.bankAccount.paymentTokenId))
          .remitter(remitter: DepositRequest.Remitter(
            name: self.viewModel.relayName.value,
            accountNumber: self.viewModel.relayBankNumber.value,
            bankName: self.viewModel.relayBank.value)).build(depositAmount: requestAmount)
        dest.depositRequest = depositRequest
        dest.selectedReceiveBank = viewModel.selectedReceiveBank
      }
    }

    if segue.identifier == DepositThirdPartWebViewController.segueIdentifier {
      if let dest = segue.destination as? DepositThirdPartWebViewController {
        dest.transaction = sender as? DepositTransaction
        dest
          .cashAmount =
          CashAmount(amount: Double(self.viewModel.relayBankAmount.value.replacingOccurrences(of: ",", with: ""))!)
        dest.remitter = DepositRequest.Remitter(
          name: self.viewModel.relayName.value,
          accountNumber: self.viewModel.relayBankNumber.value,
          bankName: self.viewModel.relayBank.value)
      }
    }
  }

  @IBAction
  func depositConfirm(_: Any) {
    if depositType is DepositRequest.DepositTypeOffline {
      performSegue(withIdentifier: DepositOfflineConfirmViewController.segueIdentifier, sender: nil)
    }

    if depositType is DepositRequest.DepositTypeThirdParty {
      depositOnline()
    }
  }

  fileprivate func initUI() {
    (self.remitterBankTextField.text <-> self.viewModel.relayBank).disposed(by: self.disposeBag)
    (self.remitterNameTextField.text <-> self.viewModel.relayName).disposed(by: self.disposeBag)
    (self.remitterAmountTextField.text <-> self.viewModel.relayBankAmount).disposed(by: self.disposeBag)
    remitterAmountTextField.editingChangedHandler = { str in
      guard let amount = Double(str)?.currencyFormatWithoutSymbol() else { return }
      self.viewModel.relayBankAmount.accept(amount)
    }

    scrollView.backgroundColor = UIColor.black_two
    depositTableView.addBorderTop(size: 1, color: UIColor.dividerCapeCodGray2)
    titleLabel.text = Localize.string("deposit_offline_step1_title")
    selectDepositBankLabel.text = Localize.string("deposit_selectbank")
    myDepositInfo.text = Localize.string("deposit_my_account_detail")
    remitterBankTextField.setTitle(Localize.string("deposit_bankname_placeholder"))
    remitterNameTextField.setTitle(Localize.string("deposit_name"))
    remitterBankCardNumberTextField.setTitle(Localize.string("deposit_accountlastfournumber"))
    remitterAmountTextField.setTitle(Localize.string("deposit_amount"))
    if let offline = depositType as? DepositRequest.DepositTypeOffline {
      let max = offline.max.amount.currencyFormatWithoutSymbol(precision: 2)
      let min = offline.min.amount.currencyFormatWithoutSymbol(precision: 2)
      depositLimitLabel.text = String(format: Localize.string("deposit_offline_step1_tips"), min + "-" + max)
      viewModel.minAmountLimit = offline.min.amount
      viewModel.maxAmountLimit = offline.max.amount
    }

    depositConfirmButton.isValid = false
    remitterAmountTextField.setKeyboardType(UIKeyboardType.numberPad)
    remitterBankCardNumberTextField.setKeyboardType(.numberPad)
    bankTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    bankTableView.backgroundColor = UIColor.inputBaseMineShaftGray
    remitterBankCardNumberTextField.maxLength = 4
    remitterBankCardNumberTextField.numberOnly = true
    remitterAmountTextField.numberOnly = true
  }

  fileprivate func thirdPartDataBinding() {
    let getDepositOfflineBankAccountsObservable = viewModel.getDepositMethods(depositType: depositType!.depositTypeId)
      .asObservable()
    getDepositOfflineBankAccountsObservable.bind(to: depositTableView.rx.items(
      cellIdentifier: String(describing: DepositMethodTableViewCell.self),
      cellType: DepositMethodTableViewCell.self))
    { index, data, cell in
      cell.setUp(icon: "Default(32)", name: data.displayName, index: index, selectedIndex: self.selectedIndex)
    }.disposed(by: disposeBag)

    getDepositOfflineBankAccountsObservable
      .subscribeOn(MainScheduler.instance)
      .subscribe { data in
        self.constraintBankTableHeight.constant = CGFloat(data.count * 56)
        self.depositTableView.layoutIfNeeded()
        self.depositTableView.addBorderBottom(size: 1, color: UIColor.dividerCapeCodGray2)
        guard let firstSelectedMethod = data.first else { return }
        self.viewModel.selectedMethod = firstSelectedMethod
        let max = firstSelectedMethod.depositLimitMaximum.currencyFormatWithoutSymbol(precision: 2)
        let min = firstSelectedMethod.depositLimitMinimum.currencyFormatWithoutSymbol(precision: 2)
        self.depositLimitLabel.text = String(format: Localize.string("deposit_offline_step1_tips"), min + "-" + max)
        self.viewModel.minAmountLimit = firstSelectedMethod.depositLimitMinimum
        self.viewModel.maxAmountLimit = firstSelectedMethod.depositLimitMaximum
      } onError: { error in
        self.handleUnknownError(error)
      }.disposed(by: disposeBag)
  }

  fileprivate func thirdPartEventHandler() {
    Observable.zip(depositTableView.rx.itemSelected, depositTableView.rx.modelSelected(DepositRequest.DepositTypeMethod.self))
      .bind { indexPath, data in
        guard let cell = self.depositTableView.cellForRow(at: indexPath) as? DepositMethodTableViewCell else { return }
        guard
          let lastCell = self.depositTableView
            .cellForRow(at: IndexPath(item: self.selectedIndex, section: 0)) as? DepositMethodTableViewCell else { return }
        lastCell.unSelectRow()
        cell.selectRow()
        self.selectedIndex = indexPath.row
        self.viewModel.selectedMethod = data

        let max = data.depositLimitMaximum.currencyFormatWithoutSymbol(precision: 2)
        let min = data.depositLimitMinimum.currencyFormatWithoutSymbol(precision: 2)
        self.depositLimitLabel.text = String(format: Localize.string("deposit_offline_step1_tips"), min + "-" + max)
        self.viewModel.minAmountLimit = data.depositLimitMinimum
        self.viewModel.maxAmountLimit = data.depositLimitMaximum
      }.disposed(by: disposeBag)
  }

  fileprivate func offlineDataBinding() {
    let getDepositOfflineBankAccountsObservable = viewModel.getDepositOfflineBankAccounts().asObservable()
    getDepositOfflineBankAccountsObservable.bind(to: depositTableView.rx.items(
      cellIdentifier: String(describing: DepositMethodTableViewCell.self),
      cellType: DepositMethodTableViewCell.self))
    { index, data, cell in
      guard let bank = data.bank else { return }
      cell.setUp(
        icon: self.viewModel.getBankIcon(bank.bankId),
        name: bank.name,
        index: index,
        selectedIndex: self.selectedIndex)
    }.disposed(by: disposeBag)

    getDepositOfflineBankAccountsObservable
      .subscribeOn(MainScheduler.instance)
      .subscribe { data in
        self.constraintBankTableHeight.constant = CGFloat(data.count * 56)
        self.depositTableView.layoutIfNeeded()
        self.depositTableView.addBorderBottom(size: 1, color: UIColor.dividerCapeCodGray2)
        guard let firstSelectedBank = data.first else { return }
        self.viewModel.selectedReceiveBank = firstSelectedBank
      } onError: { error in
        self.handleUnknownError(error)
      }.disposed(by: disposeBag)
  }

  fileprivate func offlineEventHandle() {
    Observable.zip(depositTableView.rx.itemSelected, depositTableView.rx.modelSelected(FullBankAccount.self))
      .bind { indexPath, data in
        self.depositTableView.deselectRow(at: indexPath, animated: true)
        guard let cell = self.depositTableView.cellForRow(at: indexPath) as? DepositMethodTableViewCell else { return }
        guard
          let lastCell = self.depositTableView
            .cellForRow(at: IndexPath(item: self.selectedIndex, section: 0)) as? DepositMethodTableViewCell else { return }
        lastCell.unSelectRow()
        cell.selectRow()
        self.selectedIndex = indexPath.row
        self.viewModel.selectedReceiveBank = data
      }.disposed(by: disposeBag)
  }

  fileprivate func banksDataBinding() {
    viewModel.getBanks().subscribe { banks in
      self.viewModel.Allbanks = banks
      self.viewModel.filterBanks.accept(banks)
    } onError: { error in
      self.handleUnknownError(error)
    }.disposed(by: disposeBag)

    self.viewModel.filterBanks
      .bind(to: bankTableView.rx.items(cellIdentifier: "Cell", cellType: UITableViewCell.self)) { _, item, cell in
        cell.textLabel?.text = item.name
        cell.textLabel?.textColor = UIColor.textPrimaryDustyGray
        cell.backgroundColor = UIColor.inputBaseMineShaftGray
      }.disposed(by: disposeBag)
  }

  fileprivate func banksEventHandle() {
    remitterBankTextField.showPickerView = { [unowned self] in
      DispatchQueue.main.async {
        self.bankTableView.isHidden = false
        let offsetY = self.scrollView.contentOffset.y == 0 ? self.view.frame.height * 0.05 : self.scrollView.contentOffset
          .y
        self.constraintAllBankTableHeight.constant = self.remitterBankTextField.frame.origin.y - offsetY
        self.scrollView.addSubview(self.bankTableView)
      }
    }

    remitterBankTextField.hidePickerView = { [unowned self] in
      if viewModel.filterBanks.value.count != 0 {
        let indexPath = IndexPath(row: 0, section: 0)
        self.bankTableView.scrollToRow(at: indexPath, at: .top, animated: true)
      }

      self.bankTableView.isHidden = true
    }

    remitterBankTextField.editingChangedHandler = { str in
      if str == "" {
        self.viewModel.filterBanks.accept(self.viewModel.Allbanks)
        return
      }

      let filterBanks = self.viewModel.Allbanks.filter { bank -> Bool in
        bank.name.contains(str)
      }

      self.viewModel.filterBanks.accept(filterBanks)
    }

    Observable.zip(bankTableView.rx.itemSelected, bankTableView.rx.modelSelected(SimpleBank.self)).bind { indexPath, data in
      self.bankTableView.deselectRow(at: indexPath, animated: true)
      guard self.bankTableView.cellForRow(at: indexPath) != nil else { return }
      self.viewModel.relayBank.accept(data.name)
      self.bankTableView.isHidden = true
      self.remitterBankTextField.textContent.resignFirstResponder()
    }.disposed(by: disposeBag)
  }

  fileprivate func validateOfflineInputTextField() {
    validateInputTextField()
    viewModel.event().bankValid.subscribe { [weak self] isValid in
      guard let isValid = isValid.element, self?.remitterBankTextField.isEdited ?? false else { return }
      let message = isValid ? "" : Localize.string("common_field_must_fill")
      self?.remitterBankErrorLabel.text = message
    }.disposed(by: disposeBag)
    viewModel.event()
      .offlineDataValid
      .bind(to: depositConfirmButton.rx.valid)
      .disposed(by: disposeBag)
  }

  fileprivate func validateOnlineInputTextField() {
    validateInputTextField()
    viewModel.event()
      .onlinieDataValid
      .bind(to: depositConfirmButton.rx.valid)
      .disposed(by: disposeBag)
  }

  fileprivate func validateInputTextField() {
    viewModel.event().userNameValid.subscribe { [weak self] isValid in
      guard let isValid = isValid.element, self?.remitterNameTextField.isEdited ?? false else { return }
      let message = isValid ? "" : Localize.string("common_field_must_fill")
      self?.remitterNameErrorLabel.text = message
    }.disposed(by: disposeBag)

    viewModel.event().amountValid.subscribe { [weak self] isValid in
      guard let isValid = isValid.element, self?.remitterAmountTextField.isEdited ?? false else { return }
      let message = isValid ? "" : self?.viewModel.relayBankAmount.value.count == 0 ? Localize
        .string("common_field_must_fill") : Localize.string("deposit_limitation_hint")
      self?.remitterAmountErrorLabel.text = message
    }.disposed(by: disposeBag)
  }

  fileprivate func depositOnline() {
    self.viewModel.depositOnline(depositTypeId: self.depositType?.depositTypeId ?? 0).subscribe { transaction in
      let title = Localize.string("common_kindly_remind")
      let message = Localize.string("deposit_thirdparty_transaction_remind")
      Alert.show(title, message, confirm: {
        self.performSegue(withIdentifier: DepositThirdPartWebViewController.segueIdentifier, sender: transaction)
      }, cancel: nil)
    } onError: { error in
      self.handleUnknownError(error)
    }.disposed(by: disposeBag)
  }
}
