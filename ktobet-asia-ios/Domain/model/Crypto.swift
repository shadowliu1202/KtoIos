import SharedBu
import UIKit

extension Crypto {
  @objc var icon: UIImage? {
    nil
  }

  @objc var currencyId: Int {
    0
  }
}

extension Crypto.Ethereum {
  static func create() -> Crypto {
    Crypto.Companion().create(simpleName: Crypto.Ethereum().simpleName)
  }

  @objc override var icon: UIImage? {
    UIImage(named: "IconCrypto")
  }

  @objc override var flagIcon: UIImage? {
    UIImage(named: "IconCryptoTypeETH")
  }

  @objc override var currencyId: Int {
    1001
  }
}
