import SharedBu

extension ArcadeGame: WebGameWithDuplicatable {
    func duplicate(isFavorite: Bool) -> WebGameWithDuplicatable {
        return ArcadeGame(gameId: self.gameId, gameName: self.gameName, isFavorite: isFavorite, gameStatus: self.gameStatus, thumbnail: self.thumbnail)
    }
}
