import sharedbu

extension ArcadeGame: WebGameWithDuplicatable {
  func duplicate(isFavorite: Bool) -> WebGameWithDuplicatable {
    ArcadeGame(
      gameId: self.gameId,
      gameName: self.gameName,
      isFavorite: isFavorite,
      gameStatus: self.gameStatus,
      thumbnail: self.thumbnail,
      requireNoBonusLock: self.requireNoBonusLock)
  }
}
