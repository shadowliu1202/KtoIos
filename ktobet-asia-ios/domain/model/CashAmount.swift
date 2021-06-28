import Foundation
import SharedBu

extension CashAmount: Comparable {
    static public func < (lhs: CashAmount, rhs: CashAmount) -> Bool {
        return lhs.amount < rhs.amount
    }
    
    static public func == (lhs: CashAmount, rhs: CashAmount) -> Bool {
        return lhs.amount == rhs.amount
    }
}
