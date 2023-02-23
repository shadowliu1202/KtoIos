import SharedBu

extension CryptoCurrency {
  static func * (lhs: CryptoCurrency, rhs: IExchangeRate) -> AccountCurrency {
    lhs.times(exchangeRate: rhs)
  }
}
