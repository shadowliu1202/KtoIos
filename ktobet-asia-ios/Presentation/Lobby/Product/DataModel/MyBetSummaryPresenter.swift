import RxSwift
import sharedbu

class MyBetSummary {
    var unfinishGameCount: Int32 = 0
    var finishedGame: [Record] = []
  
    struct Record {
        let count: Int
        let createdDateTime: String
        let totalStakes: AccountCurrency
        let totalWinLoss: AccountCurrency
    }
}
