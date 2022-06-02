import Foundation
import RxSwift
import SharedBu
import RxCocoa


class AddBankViewModel {
    
    let InitAndKeyboardFirstEvent = 2

    var userName = BehaviorRelay<String>(value: "")
    
    lazy var bankID = BehaviorRelay<Int32>(value: 0)
    private var bankNames: [String] = []
    lazy var bankName = BehaviorRelay<String>(value: "")
    lazy var bankValid: Observable<ValidError> = bankName.skip(InitAndKeyboardFirstEvent).map { [unowned self] (bankName) -> ValidError in
        let result: BankNamePatternValidateResult = self.accountPatternGenerator.bankName(banks: self.bankNames).validate(name: bankName)
        return result.toValidError()
    }

    private lazy var isBankValid = bankValid.map({$0 == .none ? true : false})
    lazy var branchName = BehaviorRelay<String>(value: "")
    lazy var branchValid: Observable<ValidError> = branchName.skip(InitAndKeyboardFirstEvent).map { [unowned self] (text) -> ValidError in
        let result: BankBranchPatternValidateResult = self.accountPatternGenerator.bankBranch().validate(name: text)
        return result.toValidError()
    }

    private lazy var isBranchValid = branchValid.map({$0 == .none ? true : false})
    lazy var areaName = AreaNameFactory.Companion.init().create(supportLocale: playerDataUseCase.getSupportLocalFromCache())
    var province = BehaviorRelay<String>(value: "")
    lazy var provinceValid = province.skip(InitAndKeyboardFirstEvent).map({ [weak self] (txt) -> ValidError in
        if let `self` = self, self.isProvinceLegal(txt) {
            return .none
        }
        return .empty
    })
    lazy var isProvinceValid = provinceValid.map({$0 == .none ? true : false})
    func isProvinceLegal(_ input: String) -> Bool {
        if input.count > 0, self.getProvinces().contains(input) {
            return true
        }
        return false
    }
    
    var county = BehaviorRelay<String>(value: "")
    lazy var countyValid: Observable<ValidError> = county.skip(InitAndKeyboardFirstEvent).map({ [weak self] (txt) in
        if let `self` = self, self.isCountyLegal(txt) {
            return .none
        }
        return .empty
    })
    private lazy var isCountyValid = countyValid.map({$0 == .none ? true : false})
    func isCountyLegal(_ input: String) -> Bool {
        let txt = province.value
        if self.getCountries(province: txt).contains(county.value) {
            return true
        }
        return false
    }
    func resetCountyIfNotEmpty() {
        if self.county.value.count > 0 {
            self.county.accept("")
        }
    }
    
    var account = BehaviorRelay<String>(value: "")
    lazy var accontValid: Observable<ValidError> = account.skip(InitAndKeyboardFirstEvent).map { [unowned self] (text) -> ValidError in
        if text.count == 0 {
            return .empty
        } else if !self.accountPatternGenerator.bankAccountNumber().verify(name: text) {
            return .length
        } else {
            return .none
        }
    }
    private lazy var isAccountValid = accontValid.map({$0 == .none ? true : false})
    
    lazy var btnValid: Observable<Bool> = Observable.combineLatest(isBankValid, isBranchValid, isProvinceValid, isCountyValid, isAccountValid) {
        return $0 && $1 && $2 && $3 && $4
    }.startWith(false)
    
    private let localStorageRepo: PlayerLocaleConfiguration
    private var usecaseAuth : AuthenticationUseCase!
    private var bankUseCase: BankUseCase!
    private var withdrawalUseCase: WithdrawalUseCase!
    private var playerDataUseCase: PlayerDataUseCase!
    private var accountPatternGenerator: AccountPatternGenerator!
    
    init(_ localStorageRepo: PlayerLocaleConfiguration,
         _ authenticationUseCase : AuthenticationUseCase,
         _ bankUseCase: BankUseCase,
         _ withdrawalUseCase: WithdrawalUseCase,
         _ playerDataUseCase: PlayerDataUseCase,
         _ accountPatternGenerator: AccountPatternGenerator) {
        self.localStorageRepo = localStorageRepo
        self.usecaseAuth = authenticationUseCase
        self.bankUseCase = bankUseCase
        self.withdrawalUseCase = withdrawalUseCase
        self.playerDataUseCase = playerDataUseCase
        self.userName.accept(usecaseAuth.getUserName())
        self.accountPatternGenerator = accountPatternGenerator
    }
    
    func isRealNameEditable() -> Single<Bool> {
        return playerDataUseCase.isRealNameEditable()
    }
    
    func getBanks() -> Single<[(Int, Bank)]> {
        return bankUseCase.getBankMap().do(onSuccess: { [unowned self] (tuple) in
            self.bankNames = tuple.map{ self.displayBank($0.1) }
        })
    }
    
    func getProvinces() -> [String] {
        return areaName.getProvinces().map({ $0.name })
    }
    
    func getCountries(province: String) -> [String] {
        return areaName.getCities(province: Province(name: province)).map({ $0.name })
    }
    
    func addWithdrawalAccount() -> Completable {
        var bankId = self.bankID.value
        if !bankNames.contains(self.bankName.value) {
            bankId = 0
        }
        let pureBankName = StringMapper.sharedInstance.splitShortNameAndBankName(bankName: self.bankName.value)
        let newWithdrawalAccount: NewWithdrawalAccount = NewWithdrawalAccount(bankId: bankId, bankName: pureBankName, branch: self.branchName.value, location: self.province.value, city: self.county.value, address: "", accountNumber: self.account.value , accountName: self.userName.value)
        return withdrawalUseCase.addWithdrawalAccount(newWithdrawalAccount)
    }

    private func displayBank(_ bank: Bank) -> String {
        switch localStorageRepo.getSupportLocale() {
        case is SupportLocale.China:
            return bank.name
        case is SupportLocale.Vietnam:
            return "(\(bank.shortName)) \(bank.name)"
        default:
            return ""
        }
    }
}
