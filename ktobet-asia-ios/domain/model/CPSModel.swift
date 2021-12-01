import SharedBu
import UIKit
import Foundation

protocol CryptoUIResource {
    var flagIcon: UIImage? { get }
    var icon: UIImage? { get }
    var currencyId: Int { get }
    var name: String { get }
}
extension CurrencyUnit: CryptoUIResource {
    @objc var flagIcon: UIImage? {
        return nil
    }
    @objc var icon: UIImage? {
        return nil
    }
    @objc var currencyId: Int {
        return 0
    }
    @objc var name: String {
        return simpleName
    }
}

extension CryptoCurrency {
    @objc override var flagIcon: UIImage? {
        return UIImage(named: "IconCryptoTypeETH")
    }
    @objc override var currencyId: Int {
        return 1001
    }
}

extension AccountCurrency {
    @objc override var flagIcon: UIImage? {
        return UIImage(named: "IconCryptoTypeCNY")
    }
}

extension SupportCryptoType: CryptoUIResource {
    class func valueOf(_ rawData: String) -> SupportCryptoType {
        switch rawData.uppercased() {
        case "ETH":
            return .eth
        case "USDT":
            return .usdt
        case "USDC":
            return .usdc
        default:
            fatalError("\(rawData) is not support")
        }
    }
    var icon: UIImage? {
        return UIImage(named: "IconCrypto")
    }
    var flagIcon: UIImage? {
        return nil
    }
    var currencyId: Int {
        Int(self.id__)
    }
}

extension CryptoAmount {
    static func create(cryptoAmount: Double, crypto: Crypto) -> CryptoAmount {
        return CryptoAmount.Companion.init().create(cryptoAmount: cryptoAmount, crypto: crypto)
    }
    static func create(cryptoAmount: String, crypto: Crypto) -> CryptoAmount {
        return CryptoAmount.Companion.init().create(cryptoAmount: cryptoAmount, crypto_: crypto)
    }
}
