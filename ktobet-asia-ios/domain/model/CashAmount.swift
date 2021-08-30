import Foundation
import SharedBu

extension CashAmount: Comparable {
    var amount: Double {
        return self.amount_
    }
    
    static public func < (lhs: CashAmount, rhs: CashAmount) -> Bool {
        return lhs.amount < rhs.amount
    }
    
    static public func == (lhs: CashAmount, rhs: CashAmount) -> Bool {
        return lhs.amount == rhs.amount
    }
}
