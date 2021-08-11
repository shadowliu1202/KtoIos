import Foundation
import SharedBu
import UIKit

extension SlotGame: WebGameWithDuplicatable {
    func duplicate(isFavorite: Bool) -> WebGameWithDuplicatable {
        return SlotGame(gameId: self.gameId, gameName: self.gameName, isFavorite: isFavorite, gameStatus: self.gameStatus, thumbnail: self.thumbnail, hasForFun: self.hasForFun, jackpotPrize: self.jackpotPrize)
    }
}
