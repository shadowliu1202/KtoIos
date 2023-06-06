import SharedBu

extension AccountCurrency {
  class func zero() -> AccountCurrency {
    "0".toAccountCurrency()
  }

  static func + (lhs: AccountCurrency, rhs: AccountCurrency) -> AccountCurrency {
    lhs.plus(addend: rhs)
  }

  static func - (lhs: AccountCurrency, rhs: AccountCurrency) -> AccountCurrency {
    lhs.minus(minus: rhs)
  }

  static func * (lhs: AccountCurrency, rhs: IExchangeRate) -> CryptoCurrency {
    lhs.times(exchangeRate: rhs)
  }

  static func > (lhs: AccountCurrency, rhs: AccountCurrency) -> Bool {
    lhs.compareTo(other: rhs) > 0
  }

  static func >= (lhs: AccountCurrency, rhs: AccountCurrency) -> Bool {
    lhs.compareTo(other: rhs) >= 0
  }

  static func == (lhs: AccountCurrency, rhs: AccountCurrency) -> Bool {
    lhs.compareTo(other: rhs) == 0
  }

  static func < (lhs: AccountCurrency, rhs: AccountCurrency) -> Bool {
    lhs.compareTo(other: rhs) < 0
  }

  static func <= (lhs: AccountCurrency, rhs: AccountCurrency) -> Bool {
    lhs.compareTo(other: rhs) <= 0
  }

  static func != (lhs: AccountCurrency, rhs: AccountCurrency) -> Bool {
    lhs.compareTo(other: rhs) != 0
  }
}
