import Foundation
import sharedbu

extension Int {
  func toSupportCryptoType() -> SupportCryptoType? {
    for index in 0..<SupportCryptoType.values().size {
      if (SupportCryptoType.values().get(index: index))!.id__ == self {
        return SupportCryptoType.values().get(index: index)
      }
    }

    return nil
  }
}
