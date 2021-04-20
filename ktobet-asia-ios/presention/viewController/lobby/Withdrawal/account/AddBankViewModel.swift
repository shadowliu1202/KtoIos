import Foundation
import RxSwift
import share_bu
import RxCocoa

class AddBankViewModel {
    enum ValidError {
        case none
        case length
        case empty
        case regex
    }
    var userName = BehaviorRelay<String>(value: "")
    
    lazy var bankName = BehaviorRelay<String>(value: "")
    lazy var bankID = BehaviorRelay<Int32>(value: 0)
    private var bankNames: [String] = []
    private lazy var isBankValid = bankName.distinctUntilChanged().map({$0.count > 0})
    lazy var bankValid: Observable<ValidError> = isBankValid.skip(1).flatMap { [weak self] (isValid) -> Observable<ValidError> in
        self?.flatValid(isValid) ?? Observable<ValidError>.just(.none)
    }
    
    lazy var branchName = BehaviorRelay<String>(value: "")
    private lazy var isBranchValid = branchValid.flatMap { (validError) -> Observable<Bool> in
        return Observable.just(validError == .none ? true : false)
    }
    lazy var branchValid: Observable<ValidError> = branchName.distinctUntilChanged().skip(1).map { (text) -> ValidError in
        return text.count > 0 ? (text.isValidRegex(format: .branchName) ? .none : .regex) : .empty
    }
    
    var province = BehaviorRelay<String>(value: "")
    lazy var isProvinceValid = province.map({$0.count > 0})
    
    var country = BehaviorRelay<String>(value: "")
    private lazy var isCountryValid = countryValid.flatMap { (validError) -> Observable<Bool> in
        return Observable.just(validError == .none ? true : false)
    }
    lazy var countryValid: Observable<ValidError> = country.distinctUntilChanged().skip(1).map({$0.count > 0 ? .none : .empty})
    
    var account = BehaviorRelay<String>(value: "")
    private lazy var isAccountValid = accontValid.flatMap { (validError) -> Observable<Bool> in
        return Observable.just(validError == .none ? true : false)
    }
    lazy var accontValid: Observable<ValidError> = account.distinctUntilChanged().skip(1).map { (text) -> ValidError in
        if text.count == 0 {
            return .empty
        } else if text.count < 10 {
            return .length
        } else {
            return .none
        }
    }
    
    lazy var btnValid: Observable<Bool> = Observable.combineLatest(isBankValid, isBranchValid, isProvinceValid, isCountryValid, isAccountValid) {
        return $0 && $1 && $2 && $3 && $4
    }.startWith(false)
    
    private var usecaseAuth : AuthenticationUseCase!
    private var bankUseCase: BankUseCase!
    private var withdrawalUseCase: WithdrawalUseCase!
    private var playerDataUseCase: PlayerDataUseCase!
    
    init(_ authenticationUseCase : AuthenticationUseCase,
         _ bankUseCase: BankUseCase,
         _ withdrawalUseCase: WithdrawalUseCase,
         _ playerDataUseCase: PlayerDataUseCase) {
        self.usecaseAuth = authenticationUseCase
        self.bankUseCase = bankUseCase
        self.withdrawalUseCase = withdrawalUseCase
        self.playerDataUseCase = playerDataUseCase
        self.userName.accept(usecaseAuth.getUserName())
    }
    
    func flatValid(_ isValid: Bool) -> Observable<ValidError>{
        switch isValid {
        case true:
            return Observable.just(ValidError.none)
        case false:
            return Observable.just(ValidError.empty)
        }
    }
    
    func isRealNameEditable() -> Single<Bool> {
        return playerDataUseCase.isRealNameEditable()
    }
    
    func getBanks() -> Single<[(Int, Bank)]> {
        return bankUseCase.getBankMap().do(onSuccess: { [weak self] (tuple) in
            self?.bankNames = tuple.map{ $0.1.name }
        })
    }
    
    func getProvinces() -> [String] {
        return ChinaProvince().provinces
    }
    
    func getCountries(province: String) -> [String] {
        return ChinaProvince().provinceCities[province] ?? []
    }
    
    func addWithdrawalAccount() -> Completable {
        var bankId = self.bankID.value
        if !bankNames.contains(self.bankName.value) {
            bankId = 0
        }
        let newWithdrawalAccount: NewWithdrawalAccount = NewWithdrawalAccount(bankId: bankId, bankName: self.bankName.value, branch: self.branchName.value, location: self.province.value, city: self.country.value, address: "", accountNumber: self.account.value , accountName: self.userName.value)
        return withdrawalUseCase.addWithdrawalAccount(newWithdrawalAccount)
    }
}
