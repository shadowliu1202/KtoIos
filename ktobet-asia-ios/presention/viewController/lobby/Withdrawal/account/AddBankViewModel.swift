import Foundation
import RxSwift
import share_bu
import RxCocoa

class AddBankViewModel {
    enum ValidError {
        case none
        case empty
    }
    var userName = BehaviorRelay<String>(value: "")
    
    lazy var bankName = BehaviorRelay<String>(value: "")
    lazy var bankID = BehaviorRelay<Int32>(value: 0)
    private lazy var isBankValid = bankName.distinctUntilChanged().map({$0.count > 0})
    lazy var bankValid: Observable<ValidError> = isBankValid.skip(1).flatMap { [weak self] (isValid) -> Observable<ValidError> in
        self?.flatValid(isValid) ?? Observable<ValidError>.just(.none)
    }
    
    lazy var branchName = BehaviorRelay<String>(value: "")
    private lazy var isBranchValid = branchName.distinctUntilChanged().map({$0.count > 0})
    lazy var branchValid: Observable<ValidError> = isBranchValid.skip(1).flatMap { [weak self] (isValid) -> Observable<ValidError> in
        self?.flatValid(isValid) ?? Observable<ValidError>.just(.none)
    }
    
    var province = BehaviorRelay<String>(value: "")
    lazy var isProvinceValid = province.map({$0.count > 0})
    
    var country = BehaviorRelay<String>(value: "")
    private lazy var isCountryValid = country.map({$0.count > 0})
    
    var account = BehaviorRelay<String>(value: "")
    private lazy var isAccountValid = account.distinctUntilChanged().map({$0.count > 9})
    lazy var accontValid: Observable<ValidError> = isAccountValid.skip(1).flatMap { [weak self] (isValid) -> Observable<ValidError> in
        self?.flatValid(isValid) ?? Observable<ValidError>.just(.none)
    }
    
    lazy var btnValid: Observable<Bool> = Observable.combineLatest(isBankValid, isBranchValid, isProvinceValid, isCountryValid, isAccountValid) {
        return $0 && $1 && $2 && $3 && $4
    }
    
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
        return bankUseCase.getBankMap()
    }
    
    func getProvinces() -> [String] {
        return ChinaProvince().provinces
    }
    
    func getCountries(province: String) -> [String] {
        return ChinaProvince().provinceCities[province] ?? []
    }
    
    func addWithdrawalAccount() -> Completable {
        let newWithdrawalAccount: NewWithdrawalAccount = NewWithdrawalAccount(bankId: self.bankID.value, bankName: self.bankName.value, branch: self.branchName.value, location: self.province.value, city: self.country.value, address: "", accountNumber: self.account.value, accountName: self.userName.value)
        return withdrawalUseCase.addWithdrawalAccount(newWithdrawalAccount)
    }
}
