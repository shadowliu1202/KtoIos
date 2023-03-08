import Foundation
import RxCocoa
import RxSwift
import SharedBu

class CryptoViewModel {
  private var withdrawalUseCase: WithdrawalUseCase!
  private lazy var withdrawalSystem = withdrawalUseCase.getWithdrawalSystem()
  lazy var supportCryptoTypes = withdrawalSystem.map({ $0.supportCryptos() })

  init(withdrawalUseCase: WithdrawalUseCase) {
    self.withdrawalUseCase = withdrawalUseCase
  }
}
