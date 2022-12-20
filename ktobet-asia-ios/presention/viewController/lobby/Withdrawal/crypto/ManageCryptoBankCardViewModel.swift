import Foundation
import SharedBu
import RxSwift
import RxCocoa


class ManageCryptoBankCardViewModel {
    static let accountNameMaxLength: Int32 = 20
    static let accountAddressMaxLength: Int32 = 50
    var accountName = BehaviorRelay<String>(value: "")
    var accountAddress = BehaviorRelay<String>(value: "")
    var selectedCryptoType = BehaviorRelay<String>(value: "")
    lazy var selectedCryptoNetwork = BehaviorRelay<String>(value: "")
    lazy var supportCryptoNetwork = BehaviorRelay<[CryptoNetwork]>(value: [])
    
    private var withdrawalUseCase: WithdrawalUseCase!
    private let disposeBag = DisposeBag()
    
    init(withdrawalUseCase: WithdrawalUseCase) {
        self.withdrawalUseCase = withdrawalUseCase
        selectedCryptoType.filter({!$0.isEmpty}).subscribe(onNext: { [unowned self] in
            self.refreshSupportNetworks($0)
            self.refreshSelectedNetworks($0)
        }).disposed(by: disposeBag)
    }
    
    private func refreshSupportNetworks(_ cryptoType: String) {
        let crypto = SupportCryptoType.valueOf(cryptoType)
        let supportNetworks = crypto.supportNetwork()
        self.supportCryptoNetwork.accept(supportNetworks)
    }
    
    private func refreshSelectedNetworks(_ cryptoType: String) {
        let crypto = SupportCryptoType.valueOf(cryptoType)
        let supportNetworks = crypto.supportNetwork()
        let originNetwork = self.selectedCryptoNetwork.value
        if !supportNetworks.map({$0.name}).contains(originNetwork), let first = supportNetworks.first {
            selectedCryptoNetwork.accept(first.name)
        }
    }
    
    func getCryptoBankCards() -> Single<[CryptoBankCard]> {
        return withdrawalUseCase.getCryptoBankCards()
    }
    
    func addCryptoBankCard() -> Single<String> {
        let currency = SupportCryptoType.valueOf(selectedCryptoType.value)
        return withdrawalUseCase.addCryptoBankCard(currency: currency, alias: accountName.value, walletAddress: accountAddress.value, cryptoNetwork: stringToCryptoNetwork())
    }
    
    func stringToCryptoNetwork() -> CryptoNetwork {
        return CryptoNetwork.valueOf(self.selectedCryptoNetwork.value)
    }
    
    func deleteCryptoAccount(_ playerBankCardId: String) -> Completable {
        withdrawalUseCase.deleteCryptoBankCard(id: playerBankCardId)
    }
    
    func isCryptoWithdrawalValid() -> Single<Bool> {
        withdrawalUseCase.isCryptoProcessCertified()
    }
    
    func event() -> (accountNameValid: Observable<Bool>,
                     accountAddressValid: Observable<ValidError>,
                     cryptoTypeValid: Observable<Bool>,
                     dataValid: Observable<Bool>) {
        let accountNameValid = accountName.map { (name) -> Bool in
            return name.count != 0
        }
        
        let accountAddressValid = Observable.combineLatest(accountAddress, selectedCryptoNetwork).map {[weak self] (address, _) -> ValidError in
            guard let cryptoNetwork = self?.stringToCryptoNetwork() else { return .empty }
            return address.count > 0 ? (cryptoNetwork.isValid(cryptoNetworkAddress: address) ? .none : .regex)  : .empty
        }
        
        let cryptoTypeValid = selectedCryptoType.map { (type) -> Bool in
            return type.count != 0
        }
        
        let dataValid = Observable.combineLatest(accountNameValid, accountAddressValid, cryptoTypeValid) {
            return $0 && $1 == .none && $2
        }
        
        return (accountNameValid, accountAddressValid, cryptoTypeValid, dataValid)
    }
}
