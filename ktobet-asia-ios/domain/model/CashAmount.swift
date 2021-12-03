import SharedBu

//TODO: Delete file when CashAmount removed.
extension CashAmount {
    static func >(lhs: CashAmount, rhs: CashAmount) -> Bool {
        return lhs.compareTo(other: rhs) > 0
    }
    
    static func >=(lhs: CashAmount, rhs: CashAmount) -> Bool {
        return lhs.compareTo(other: rhs) >= 0
    }
    
    static func ==(lhs: CashAmount, rhs: CashAmount) -> Bool {
        return lhs.compareTo(other: rhs) == 0
    }
    
    static func <(lhs: CashAmount, rhs: CashAmount) -> Bool {
        return lhs.compareTo(other: rhs) < 0
    }
    
    static func <=(lhs: CashAmount, rhs: CashAmount) -> Bool {
        return lhs.compareTo(other: rhs) <= 0
    }
    
    static func !=(lhs: CashAmount, rhs: CashAmount) -> Bool {
        return lhs.compareTo(other: rhs) != 0
    }
}
