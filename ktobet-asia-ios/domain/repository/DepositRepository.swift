import Foundation
import RxSwift
import SharedBu

protocol DepositRepository {
    //MARK: TODO 等withdrawl refactor 後移除
    func requestCryptoDetailUpdate(displayId: String) -> Single<String>
    func getPlayerDepositSystem() -> Single<DepositSystem>
}

class DepositRepositoryImpl: DepositRepository {
    private var bankApi: BankApi!
    private let depositSystem = DepositSystem.create()
    
    init(_ bankApi: BankApi) {
        self.bankApi = bankApi
    }
    
    func requestCryptoDetailUpdate(displayId: String) -> Single<String> {
        return bankApi.requestCryptoDetailUpdate(displayId: displayId).map { (response: ResponseData<CryptoDepositUrl>) -> String in
            guard let data = response.data else { return "" }
            return data.url
        }
    }
    
    func getPlayerDepositSystem() -> Single<DepositSystem> {
        return Single.just(depositSystem)
    }
}
