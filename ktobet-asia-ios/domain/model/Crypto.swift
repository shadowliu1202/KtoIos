import SharedBu
import UIKit

extension Crypto {
    @objc var icon: UIImage? {
        return nil
    }
    @objc var currencyId: Int {
        return 0
    }
    
}

extension Crypto.Ethereum {
    static func create() -> Crypto {
        return Crypto.Companion.init().create(simpleName: Crypto.Ethereum.init().simpleName)
    }
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
