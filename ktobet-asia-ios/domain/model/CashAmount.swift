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

extension AccountCurrency {
    static func create(amount: String) -> AccountCurrency {
        let repoLocal = DI.resolve(LocalStorageRepository.self)!
        return AccountCurrency.create(locale: repoLocal.getSupportLocal(), amount: amount)
    }
    
    static func create(locale: SupportLocale, amount: String) -> AccountCurrency {
        return AccountCurrency.Companion.init().create(locale: locale, amount_: amount)
    }
}
