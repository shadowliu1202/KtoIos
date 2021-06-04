import Foundation
import SharedBu
import UIKit

extension NumberGame {
    
    class func duplicateGame(_ origin: NumberGame, isFavorite: Bool) -> NumberGame {
        return NumberGame(gameId: origin.gameId, gameName: origin.gameName, isFavorite: isFavorite, gameStatus: origin.gameStatus, thumbnail: origin.thumbnail)
    }
}
