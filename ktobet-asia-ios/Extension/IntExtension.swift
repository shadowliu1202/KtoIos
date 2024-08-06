import Foundation
import sharedbu

extension Int {
    func toSupportCryptoType() -> SupportCryptoType? {
        for index in 0 ..< SupportCryptoType.allCases.count {
            if (SupportCryptoType.allCases[index]).id == self {
                return SupportCryptoType.allCases[index]
            }
        }

        return nil
    }
}

extension Int {
    func toHourMinutesFormat() -> String {
        if self <= 0 {
            return "00:00"
        }
        let mm = self / 60
        let ss = self % 60
        return String(format: "%02d:%02d", mm, ss)
    }
}
