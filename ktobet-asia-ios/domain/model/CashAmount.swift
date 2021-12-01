import Foundation
import SharedBu

extension CashAmount: Comparable {
    var amount: Double {
        return self.bigAmount.doubleValue(exactRequired: false)
    }
    
    static public func < (lhs: CashAmount, rhs: CashAmount) -> Bool {
        return lhs.amount < rhs.amount
    }
    
    static public func == (lhs: CashAmount, rhs: CashAmount) -> Bool {
        return lhs.amount == rhs.amount
    }
}
