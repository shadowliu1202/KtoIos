import Foundation
import sharedbu
import UIKit

extension SlotGame: WebGameWithDuplicatable {
  func duplicate(isFavorite: Bool) -> WebGameWithDuplicatable {
    SlotGame(
      gameId: self.gameId,
      gameName: self.gameName,
      isFavorite: isFavorite,
      gameStatus: self.gameStatus,
      thumbnail: self.thumbnail,
      hasForFun: self.hasForFun,
      jackpotPrize: self.jackpotPrize)
  }
}
