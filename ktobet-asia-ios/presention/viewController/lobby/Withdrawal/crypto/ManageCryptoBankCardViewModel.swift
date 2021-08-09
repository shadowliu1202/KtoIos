import Foundation
import SharedBu
import RxSwift
import RxCocoa


class ManageCryptoBankCardViewModel {
    static let accountNameMaxLength: Int32 = 20
    static let accountAddressMaxLength: Int32 = 50
    var accountName = BehaviorRelay<String>(value: "")
    var accountAddress = BehaviorRelay<String>(value: "")
    var cryptoType = BehaviorRelay<String>(value: "")
    
    private var withdrawalUseCase: WithdrawalUseCase!
    
    init(withdrawalUseCase: WithdrawalUseCase) {
        self.withdrawalUseCase = withdrawalUseCase
    }
    
    func getCryptoBankCards() -> Single<[CryptoBankCard]> {
        return withdrawalUseCase.getCryptoBankCards()
    }
    
    func addCryptoBankCard() -> Single<String> {
        return withdrawalUseCase.addCryptoBankCard(currency: Crypto.Companion.init().create(simpleName: cryptoType.value), alias: accountName.value, walletAddress: accountAddress.value)
    }
    
    func deleteCryptoAccount(_ playerBankCardId: String) -> Completable {
        withdrawalUseCase.deleteCryptoBankCard(id: playerBankCardId)
    }
    
    func event() -> (accountNameValid: Observable<Bool>,
                     accountAddressValid: Observable<ValidError>,
                     cryptoTypeValid: Observable<Bool>,
                     dataValid: Observable<Bool>) {
        let accountNameValid = accountName.map { (name) -> Bool in
            return name.count != 0
        }
        
        let accountAddressValid = accountAddress.map { (address) -> ValidError in
            return address.count > 0 ? (address.isValidRegex(format: .cryptoAddress) ? .none : .regex)  : .empty
        }
        
        let cryptoTypeValid = cryptoType.map { (type) -> Bool in
            return type.count != 0
        }
        
        let dataValid = Observable.combineLatest(accountNameValid, accountAddressValid, cryptoTypeValid) {
            return $0 && $1 == .none && $2
        }
        
        return (accountNameValid, accountAddressValid, cryptoTypeValid, dataValid)
    }
}
