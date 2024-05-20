import Foundation
import sharedbu
import UIKit

protocol CryptoUIResource {
    var flagIcon: UIImage? { get }
    var icon: UIImage? { get }
    var currencyId: Int { get }
    var name: String { get }
}

extension CurrencyUnit: CryptoUIResource {
    @objc var flagIcon: UIImage? {
        nil
    }

    @objc var icon: UIImage? {
        nil
    }

    @objc var currencyId: Int {
        0
    }

    @objc var name: String {
        simpleName
    }
}

extension CryptoCurrency {
    var cryptoType: SupportCryptoType {
        SupportCryptoType.valueOf(self.simpleName)
    }

    @objc override var flagIcon: UIImage? {
        switch cryptoType {
        case .eth:
            return UIImage(named: "IconCryptoType_ETH")
        case .usdt:
            return UIImage(named: "IconCryptoType_USDT")
        case .usdc:
            return UIImage(named: "IconCryptoType_USDC")
        }
    }

    @objc override var currencyId: Int {
        cryptoType.currencyId
    }
}

extension AccountCurrency {
    @objc override var flagIcon: UIImage? {
        switch self.simpleName {
        case "KVND":
            return UIImage(named: "IconCryptoType_VND")
        case "CNY":
            fallthrough
        default:
            return UIImage(named: "IconCryptoType_CNY")
        }
    }
}

extension SupportCryptoType: CryptoUIResource {
    static func valueOf(_ rawData: String) -> SupportCryptoType {
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
        switch self {
        case .eth:
            return UIImage(named: "IconCryptoMain_ETH")
        case .usdt:
            return UIImage(named: "IconCryptoMain_USDT")
        case .usdc:
            return UIImage(named: "IconCryptoMain_USDC")
        }
    }

    var flagIcon: UIImage? {
        nil
    }

    var currencyId: Int {
        Int(self.id)
    }
}

extension CryptoNetwork {
    static func valueOf(_ rawData: String) -> CryptoNetwork {
        switch rawData.uppercased() {
        case "ERC20":
            return .erc20
        case "TRC20":
            return .trc20
        default:
            fatalError("\(rawData) is not support")
        }
    }
}
