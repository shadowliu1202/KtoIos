import UIKit
import RxSwift
import RxCocoa
import SharedBu

class AddBankViewController: UIViewController {
    static let segueIdentifier = "toAddBank"
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameLabel: LockInputText!
    @IBOutlet weak var bankDropDown: DropDownInputText!
    @IBOutlet weak var bankErrorLabel: UILabel!
    @IBOutlet weak var branchTextField: InputText!
    @IBOutlet weak var branchErrorLabel: UILabel!
    @IBOutlet weak var provinceDropDown: DropDownInputText!
    @IBOutlet weak var countryDropDown: DropDownInputText!
    @IBOutlet weak var countryErrorLabel: UILabel!
    @IBOutlet weak var accountTextField: InputText!
    @IBOutlet weak var accountErrorLabel: UILabel!
    @IBOutlet weak var submitButton: UIButton!
    weak var delegate: AccountAddComplete?
    let viewModel = DI.resolve(AddBankViewModel.self)!
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        dataBinding()
    }
    
    private func initUI() {
        NavigationManagement.sharedInstance.addBackToBarButtonItem(vc: self)
        titleLabel.text = Localize.string("withdrawal_setbankaccount_button")
        nameLabel.setTitle(Localize.string("withdrawal_accountrealname"))
        bankDropDown.setTitle(Localize.string("withdrawal_bank_name"))
        bankDropDown.isSearchEnable = true
        branchTextField.setTitle(Localize.string("withdrawal_branch"))
        provinceDropDown.setTitle(Localize.string("withdrawal_bankstate"))
        provinceDropDown.optionArray = viewModel.getProvinces()
        provinceDropDown.isSearchEnable = false
        countryDropDown.setTitle(Localize.string("withdrawal_bankcity"))
        countryDropDown.isSearchEnable = false
        countryDropDown.isEnable = false
        accountTextField.setTitle(Localize.string("withdrawal_accountnumber"))
        accountTextField.setKeyboardType(.numberPad)
        accountTextField.maxLength = 25
    }
    
    private func dataBinding() {
        bindUserName()
        bindBankName()
        bindBranchName()
        bindProvince()
        bindCountry()
        bindAccount()
        bindSubmit()
    }

    private func bindUserName() {
        viewModel.userName.subscribe(onNext: { [weak self] (name) in
            self?.nameLabel.setContent(name)
        }).disposed(by: disposeBag)
        viewModel.isRealNameEditable().subscribe(onSuccess: { [weak self] (editable) in
            guard let `self` = self else {return}
            if editable {
                let gesture =  UITapGestureRecognizer(target: self, action:  #selector(self.editNameAction))
                self.nameLabel.addGestureRecognizer(gesture)
            }
        }, onError: { [weak self]  (error) in
            self?.handleUnknownError(error)
        }).disposed(by: disposeBag)
    }
    
    private func bindBankName() {
        (bankDropDown.text <-> viewModel.bankName).disposed(by: disposeBag)
        bankDropDown.selectedID.subscribe(onNext: { [weak self] (bankId) in
            if let id = bankId {
                self?.viewModel.bankID.accept(Int32(id))
            }
        }).disposed(by: disposeBag)
        viewModel.getBanks().subscribe(onSuccess: { [weak self] (tuple: [(Int, Bank)]) in
            self?.bankDropDown.optionArray = tuple.map{ $0.1.name }
            self?.bankDropDown.optionIds = tuple.map{ $0.0 }
        }, onError: { [weak self] (error) in
            self?.handleUnknownError(error)
        }).disposed(by: disposeBag)
        viewModel.bankValid.subscribe(onNext: { [weak self] (status) in
            self?.handleErrorLabel(error: status, textField: self?.bankDropDown, label: self?.bankErrorLabel)
        }).disposed(by: disposeBag)
    }
    
    private func bindBranchName() {
        (branchTextField.text <-> viewModel.branchName).disposed(by: disposeBag)
        viewModel.branchValid.subscribe(onNext: { [weak self] (status) in
            self?.handleErrorLabel(error: status, textField: self?.branchTextField, label: self?.branchErrorLabel)
        }).disposed(by: disposeBag)
    }
    
    private func bindProvince() {
        (provinceDropDown.text <-> viewModel.province).disposed(by: disposeBag)
        provinceDropDown.text.subscribe(onNext: { [weak self] (province) in
            self?.countryDropDown.optionArray = self?.viewModel.getCountries(province: province) ?? []
            self?.viewModel.country.accept("")
        }).disposed(by: disposeBag)
    }
    
    private func bindCountry() {
        viewModel.isProvinceValid.bind(to: countryDropDown.rx.isEnable).disposed(by: disposeBag)
        (countryDropDown.text <-> viewModel.country).disposed(by: disposeBag)
        viewModel.countryValid.subscribe(onNext: { [weak self] (status) in
            self?.handleErrorLabel(error: status, textField: self?.countryDropDown, label: self?.countryErrorLabel)
        }).disposed(by: disposeBag)
    }
    
    private func bindAccount() {
        (accountTextField.text <-> viewModel.account).disposed(by: disposeBag)
        viewModel.accontValid.subscribe(onNext: { [weak self] (status) in
            self?.handleErrorLabel(error: status, textField: self?.accountTextField, label: self?.accountErrorLabel)
        }).disposed(by: disposeBag)
    }
    
    private func bindSubmit() {
        viewModel.btnValid.bind(to: submitButton.rx.valid).disposed(by: disposeBag)
        submitButton.rx.touchUpInside.bind { [weak self] _ in
            guard let `self` = self else { return }
            self.viewModel.addWithdrawalAccount().subscribe(onCompleted: {
                let title = Localize.string("withdrawal_setbankaccountsuccess_modal_title")
                let message = Localize.string("withdrawal_setbankaccountsuccess_modal_content")
                Alert.show(title, message, confirm: { [weak self] in
                    self?.popThenToast()
                    self?.delegate?.addAccountSuccess()
                }, cancel: nil)
            }, onException: { [weak self] (exception) in
                self?.handleException(exception)
            }, onError: { [weak self] (error) in
                self?.handleUnknownError(error)
            }).disposed(by: self.disposeBag)
        }.disposed(by: disposeBag)
    }
    
    @objc func editNameAction() {
        let title = Localize.string("withdrawal_bankcard_change_confirm_title")
        let message = Localize.string("withdrawal_bankcard_change_confirm_content")
        Alert.show(title, message, confirm: {
            //TODO: go edit profile viewcontroler.
        }, confirmText: Localize.string("common_moveto"), cancel: {})
    }
    
    func handleErrorLabel(error: AddBankViewModel.ValidError, textField: UIView?, label: UILabel?) {
        let message = transferError(error)
        label?.text = message
        if textField is InputText {
            (textField as! InputText).showUnderline(message.count > 0)
            (textField as! InputText).setCorner(topCorner: true, bottomCorner: message.count == 0)
        } else if (textField is DropDownInputText) {
            (textField as! DropDownInputText).showUnderline(message.count > 0)
            (textField as! DropDownInputText).setCorner(topCorner: true, bottomCorner: message.count == 0)
        }
    }

    func transferError(_ error: AddBankViewModel.ValidError) -> String {
        switch error {
        case .length, .regex:
            return Localize.string("common_invalid")
        case .empty:
            return Localize.string("common_field_must_fill")
        case .none:
            return ""
        }
    }
    
    private func handleException(_ e: ApiException) {
        if e is WithdrawAccountExist {
            let title = Localize.string("bonus_applicationtips")
            let message = Localize.string("account_exist")
            Alert.show(title, message, confirm: nil, cancel: nil)
        }
    }
    
    private func popThenToast() {
        NavigationManagement.sharedInstance.popViewController({
            if let topVc = UIApplication.shared.windows.filter{ $0.isKeyWindow }.first?.topViewController {
                let toastView = ToastView(frame: CGRect(x: 0, y: 0, width: topVc.view.frame.width, height: 48))
                toastView.show(on: topVc.view, statusTip: Localize.string("withdrawal_account_added"), img: UIImage(named: "Success"))
            }
        })
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}
