import Foundation
import RxSwift
import sharedbu

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
