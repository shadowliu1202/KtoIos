import RxSwift
import SharedBu

class MyBetSummary {
    var unfinishGameCount: Int32 = 0
    var finishedGame: [Record] = []
}

struct Record {
    let count: Int
    let createdDateTime: String
    let totalStakes: CashAmount
    let totalWinLoss: CashAmount
}
