import RxSwift

class MyBetSummary {
    var unfinishGameCount: Int32 = 0
    var finishedGame: [Record] = []
}

struct Record {
    let count: Int
    let createdDateTime: String
    let totalStakes: Double
    let totalWinLoss: Double
}
