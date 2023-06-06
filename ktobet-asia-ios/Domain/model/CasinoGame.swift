import Foundation
import SharedBu
import UIKit

extension CasinoGame: WebGameWithDuplicatable {
  func duplicate(isFavorite: Bool) -> WebGameWithDuplicatable {
    CasinoGame(
      gameId: self.gameId,
      gameName: self.gameName,
      isFavorite: isFavorite,
      gameStatus: self.gameStatus,
      thumbnail: self.thumbnail,
      requireNoBonusLock: self.requireNoBonusLock,
      releaseDate: self.releaseDate)
  }
}
