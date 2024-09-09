import Foundation
import sharedbu

extension Bundle {
    var releaseVersionNumber: String {
        infoDictionary?["CFBundleShortVersionString"] as! String
    }

    var buildVersionNumber: String {
        (infoDictionary?["CFBundleVersion"] as! String)
    }

    var releaseVersionNumberPretty: String {
        "v\(releaseVersionNumber)"
    }

    var appName: String {
        infoDictionary?["CFBundleDisplayName"] as? String ?? "KTO"
    }

    var currentVersion: LocalVersion {
        let number = Int(buildVersionNumber) ?? 0
        return try! LocalVersion.companion.create(version: releaseVersionNumber, bundleVersion: "\(number)")
    }
}
