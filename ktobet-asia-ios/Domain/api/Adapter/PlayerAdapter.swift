import Foundation
import sharedbu

class PlayerAdapter: PlayerProtocol {
    private let playerAPI: PlayerApi

    init(_ playerAPI: PlayerApi) {
        self.playerAPI = playerAPI
    }

    func getCashBalance() -> SingleWrapper<ResponseItem<NSString>> {
        playerAPI._getCashBalance()
    }
}
