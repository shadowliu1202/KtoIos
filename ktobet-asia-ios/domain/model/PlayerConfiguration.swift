import Foundation
import SharedBu

extension PlayerConfiguration {
    func localeTimeZone() -> TimeZone {
        let kotlinTimeZone = self.timezone()
        return TimeZone(identifier: kotlinTimeZone.description()) ?? TimeZone.current
    }
}
