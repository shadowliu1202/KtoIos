import Foundation
import RxSwift
import SharedBu

protocol BankUseCase {
  func getBankMap() -> Single<[(Int, Bank)]>
}

class BankUseCaseImpl: BankUseCase {
  var bankRepository: BankRepository!

  init(_ bankRepository: BankRepository) {
    self.bankRepository = bankRepository
  }

  func getBankMap() -> Single<[(Int, Bank)]> {
    bankRepository.getBankMap()
  }
}
