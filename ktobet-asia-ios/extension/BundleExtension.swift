import Foundation
import SharedBu

extension Bundle {
    var releaseVersionNumber: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
    var releaseVersionNumberPretty: String {
        return "v\(releaseVersionNumber)"
    }
    var currentVersion: Version {
        if let buildNumber = self.buildVersionNumber,
           let number = Double(buildNumber) {
            return Version.companion.create(version: self.releaseVersionNumber, code: Int32(number))
        } else {
            return Version.companion.create(version: self.releaseVersionNumber)
        }
    }
}
