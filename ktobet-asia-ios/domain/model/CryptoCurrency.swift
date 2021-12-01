import SharedBu

extension CryptoCurrency {
    static func *(lhs: CryptoCurrency, rhs: IExchangeRate) -> AccountCurrency {
        return lhs.times(exchangeRate: rhs)
    }
}
