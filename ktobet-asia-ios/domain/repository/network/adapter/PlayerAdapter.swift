import Foundation
import SharedBu

class PlayerAdapter: PlayerProtocol {
  private let playerAPI: PlayerApi

  init(_ playerAPI: PlayerApi) {
    self.playerAPI = playerAPI
  }

  func getCashBalance() -> SingleWrapper<ResponseItem<NSString>> {
    playerAPI
      ._getCashBalance()
      .asReaktiveResponseItem()
  }
}
