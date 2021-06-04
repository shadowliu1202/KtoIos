import Foundation
import SharedBu
import RxSwift

protocol BankUseCase {
    func getBankMap() -> Single<[(Int, Bank)]>
}

class BankUseCaseImpl: BankUseCase {
    
    var bankRepository : BankRepository!
    
    init(_ bankRepository : BankRepository) {
        self.bankRepository = bankRepository
    }
    
    func getBankMap() -> Single<[(Int, Bank)]> {
        return bankRepository.getBankMap()
    }
}
