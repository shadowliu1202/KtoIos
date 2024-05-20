import Foundation
import SwiftKeychainWrapper

protocol KeychainStorable {
    func setInstallDate(_ date: Date)
    func getInstallDate() -> Date?
}

class Keychain: KeychainStorable {
    static let installDate = "InstallDate"

    func setInstallDate(_ date: Date) {
        let formatter = dateFormatter()
        KeychainWrapper.standard.set(formatter.string(from: date), forKey: Keychain.installDate)
    }

    func getInstallDate() -> Date? {
        guard let dateString = KeychainWrapper.standard.string(forKey: Keychain.installDate) else {
            return nil
        }

        return dateFormatter().date(from: dateString)
    }

    private func dateFormatter() -> DateFormatter {
        let formatter: DateFormatter = .init()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.timeZone = Foundation.TimeZone(abbreviation: "UTC")!
        return formatter
    }
}
