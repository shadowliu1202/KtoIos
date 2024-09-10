import Foundation
import sharedbu

struct ArcadeUnsettledSummary {
    let betTime: LocalDateTime
}

class ArcadeUnsettledRecord: WebGame {
    var betId: String = ""
    let betTime: LocalDateTime
    var gameId: Int32 = 0
    var gameName: String = ""
    var otherId: String = ""
    let stakes: AccountCurrency
    let thumbnail: ArcadeThumbnail
    var productName: String = "arcade"
    
    init(
        betId: String,
        betTime: LocalDateTime,
        gameId: Int32,
        gameName: String,
        otherId: String,
        stakes: AccountCurrency,
        thumbnail: ArcadeThumbnail
    ) {
        self.betId = betId
        self.betTime = betTime
        self.gameId = gameId
        self.gameName = gameName
        self.otherId = otherId
        self.stakes = stakes
        self.thumbnail = thumbnail
    }
}
