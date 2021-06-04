import Foundation
import SharedBu
import UIKit

extension SlotGame {
    
    class func duplicateGame(_ origin: SlotGame, isFavorite: Bool) -> SlotGame {
        return SlotGame(gameId: origin.gameId, gameName: origin.gameName, isFavorite: isFavorite, gameStatus: origin.gameStatus, thumbnail: origin.thumbnail, hasForFun: origin.hasForFun, jackpotPrize: origin.jackpotPrize)
    }

}
