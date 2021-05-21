import share_bu
import UIKit
import Foundation

extension CasinoGame {
    
    class func duplicateGame(_ origin: CasinoGame, isFavorite: Bool) -> CasinoGame {
        return CasinoGame(gameId: origin.gameId, gameName: origin.gameName, isFavorite: isFavorite, gameStatus: origin.gameStatus, thumbnail: origin.thumbnail, releaseDate: origin.releaseDate)
    }
}
