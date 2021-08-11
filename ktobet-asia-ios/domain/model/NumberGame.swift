import Foundation
import SharedBu
import UIKit

extension NumberGame: WebGameWithDuplicatable {
    func duplicate(isFavorite: Bool) -> WebGameWithDuplicatable {
        return NumberGame(gameId: self.gameId, gameName: self.gameName, isFavorite: isFavorite, gameStatus: self.gameStatus, thumbnail: self.thumbnail)
    }
}
