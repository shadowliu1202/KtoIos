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
    var cryptoNetwork = BehaviorRelay<String>(value: "")
    
    private var withdrawalUseCase: WithdrawalUseCase!
    
    init(withdrawalUseCase: WithdrawalUseCase) {
        self.withdrawalUseCase = withdrawalUseCase
    }
    
    func getCryptoBankCards() -> Single<[CryptoBankCard]> {
        return withdrawalUseCase.getCryptoBankCards()
    }
    
    func addCryptoBankCard() -> Single<String> {
        let currency = SupportCryptoType.valueOf(cryptoType.value)
        return withdrawalUseCase.addCryptoBankCard(currency: currency, alias: accountName.value, walletAddress: accountAddress.value, cryptoNetwork: stringToCryptoNetwork())
    }
    
    func stringToCryptoNetwork() -> CryptoNetwork {
        let cryptoNetworkIterator = CryptoNetwork.values().iterator()
        var cryptoNetwork: CryptoNetwork!
        while cryptoNetworkIterator.hasNext() {
            let next = (cryptoNetworkIterator.next() as! CryptoNetwork)
            if next.name == self.cryptoNetwork.value {
                cryptoNetwork = next
            }
        }
        
        return cryptoNetwork
    }
    
    func getCryptoNetworkArray() -> [CryptoNetwork] {
        var cryptoNetworkArray: [CryptoNetwork] = []
        let cryptoNetworkIterator = CryptoNetwork.values().iterator()
        while cryptoNetworkIterator.hasNext() {
            cryptoNetworkArray.append(cryptoNetworkIterator.next() as! CryptoNetwork)
        }
        
        return cryptoNetworkArray
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
        
        let accountAddressValid = Observable.combineLatest(accountAddress, cryptoNetwork).map {[weak self] (address, _) -> ValidError in
            guard let cryptoNetwork = self?.stringToCryptoNetwork() else { return .empty }
            return address.count > 0 ? (cryptoNetwork.isValid(cryptoNetworkAddress: address) ? .none : .regex)  : .empty
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
