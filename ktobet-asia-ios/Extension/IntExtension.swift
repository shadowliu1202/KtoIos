import Foundation
import sharedbu

extension Int {
  func toSupportCryptoType() -> SupportCryptoType? {
    for index in 0..<SupportCryptoType.allCases.count {
      if (SupportCryptoType.allCases[index]).id == self {
        return SupportCryptoType.allCases[index]
      }
    }

    return nil
  }
}
