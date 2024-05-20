import Foundation
import sharedbu

extension Bundle {
    var releaseVersionNumber: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    var buildVersionNumber: String? {
        infoDictionary?["CFBundleVersion"] as? String
    }

    var releaseVersionNumberPretty: String {
        "v\(releaseVersionNumber)"
    }

    var appName: String {
        infoDictionary?["CFBundleDisplayName"] as? String ?? "KTO"
    }

    var currentVersion: Version {
        if
            let buildNumber = self.buildVersionNumber,
            let number = Double(buildNumber)
        {
            return Version.companion.create(version: self.releaseVersionNumber, code: Int32(number))
        }
        else {
            return Version.companion.create(version: self.releaseVersionNumber)
        }
    }
}
