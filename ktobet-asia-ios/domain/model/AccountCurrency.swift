import SharedBu

extension AccountCurrency {
    class func zero() -> AccountCurrency {
        return "0".toAccountCurrency()
    }
    
    static func +(lhs: AccountCurrency, rhs: AccountCurrency) -> AccountCurrency {
        return lhs.plus(addend: rhs)
    }
    
    static func -(lhs: AccountCurrency, rhs: AccountCurrency) -> AccountCurrency {
        return lhs.minus(minus: rhs)
    }
    
    static func *(lhs: AccountCurrency, rhs: IExchangeRate) -> CryptoCurrency {
        return lhs.times(exchangeRate: rhs)
    }
    
    static func >(lhs: AccountCurrency, rhs: AccountCurrency) -> Bool {
        return lhs.compareTo(other: rhs) > 0
    }
    
    static func ==(lhs: AccountCurrency, rhs: AccountCurrency) -> Bool {
        return lhs.compareTo(other: rhs) == 0
    }
    
    static func <(lhs: AccountCurrency, rhs: AccountCurrency) -> Bool {
        return lhs.compareTo(other: rhs) < 0
    }
}


