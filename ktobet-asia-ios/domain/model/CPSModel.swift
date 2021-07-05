import SharedBu
import UIKit
import Foundation

extension Crypto {
    @objc var icon: UIImage? {
        return nil
    }
    @objc var currencyId: Int {
        return 0
    }
    
}

extension Crypto.Ethereum {
    @objc override var icon: UIImage? {
        return UIImage(named: "IconCrypto")
    }
    @objc override var flagIcon: UIImage? {
        return UIImage(named: "IconCryptoTypeETH")
    }
    @objc override var currencyId: Int {
        return 1001
    }
}

extension CryptoAmount {
    static func create(cryptoAmount: Double, crypto: Crypto) -> CryptoAmount {
        return CryptoAmount.Companion.init().create(cryptoAmount: cryptoAmount, crypto: crypto)
    }
}

extension Currency {
    @objc var flagIcon: UIImage? {
        return nil
    }
    
}

class FiatCurrency: Currency {
    public var simpleName: String {
        get { return "" }
    }
    static func create(cultureCode: String) -> FiatCurrency {
        switch cultureCode {
        case "zh-cn": return CNY()
        default : fatalError("Not Support")
        }
    }
}

class CNY: FiatCurrency {
    override var simpleName: String {
        get { return "CNY" }
    }
    @objc override var flagIcon: UIImage? {
        return UIImage(named: "IconCryptoTypeCNY")
    }
    
}

extension CryptoExchangeRate {
    static func create(crypto: Crypto, rate: Double) -> CryptoExchangeRate {
        return CryptoExchangeRate(crypto: crypto, rate: rate)
    }
}

