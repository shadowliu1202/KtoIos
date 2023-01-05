import SharedBu
import UIKit
import Foundation

extension CasinoGame: WebGameWithDuplicatable {
    func duplicate(isFavorite: Bool) -> WebGameWithDuplicatable {
        return CasinoGame(gameId: self.gameId, gameName: self.gameName, isFavorite: isFavorite, gameStatus: self.gameStatus, thumbnail: self.thumbnail, requireNoBonusLock: self.requireNoBonusLock, releaseDate: self.releaseDate)
    }
}
