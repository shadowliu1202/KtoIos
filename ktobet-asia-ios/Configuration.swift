import Foundation
import sharedbu
import UIKit

/// reference: https://cocoacasts.com/tips-and-tricks-managing-build-configurations-in-xocde
enum Configuration: String {
    case dev
    case qat
    case staging
    case pre_prod
    case production
    case prod_selftest
    case prod_backup

    private static let current: Configuration = {
        #if DEV
            return .dev
        #elseif QAT
            return .qat
        #elseif STAGING
            return .staging
        #elseif PREPROD
            return .pre_prod
        #elseif PRODUCTION
            return .production
        #elseif PRODUCTION_SELFTEST
            return .prod_selftest
        #elseif PRODUCTION_BACKUP
            return .prod_backup
        #endif
    }()

    private static let env: Env = switch current {
    case .dev:
        DevConfig()
    case .qat:
        QatConfig()
    case .staging:
        StagingConfig()
    case .pre_prod:
        PreProductionConfig()
    case .production:
        ProductionConfig()
    case .prod_selftest:
        ProductionSelftestConfig()
    case .prod_backup:
        ProductionBackupConfig()
    }

    static let uploadImageMBSizeLimit = 10
    static let uploadImageCountLimit = 3

    static var internetProtocol: String = env.internetProtocol
    static var hostName: [String: [String]] = env.hostName
    static var versionUpdateHostName: [String: [String]] = env.versionUpdateHostName
    static var isAutoUpdate: Bool = env.isAutoUpdate
    static var debugGesture: Bool = env.debugGesture
    static var manualControlNetwork: Bool = env.manualControlNetwork
    static var enableFileLog: Bool = env.enableFileLog
    static var enableRemoteLog: Bool = env.enableRemoteLog

    static func getKtoAgent() -> String {
        let userAgent =
            "kto-app-ios/\(UIDevice.current.systemVersion) APPv\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(UIDevice.deviceName))"
        return userAgent
    }

    static var isTesting: Bool {
        ProcessInfo.processInfo.arguments.contains("isTesting")
    }

    static var forceChinese = false
    static var supportLocale: [SupportLocale] = env.supportLocale
}

protocol Env {
    var internetProtocol: String { get }
    var hostName: [String: [String]] { get }
    var versionUpdateHostName: [String: [String]] { get }
    var isAutoUpdate: Bool { get }
    var debugGesture: Bool { get }
    var manualControlNetwork: Bool { get }
    var enableFileLog: Bool { get }
    var enableRemoteLog: Bool { get }
    var supportLocale: [SupportLocale] { get }
}

private class DevConfig: Env {
    var internetProtocol = "https://"
    var hostName: [String: [String]] = [
        SupportLocale.China.shared.cultureCode(): ["hsdev-branddev03.mobile.pivotsite.com"],
        SupportLocale.Vietnam.shared.cultureCode(): ["hsdev-branddev03.mobile.pivotsite.com"],
    ]
    lazy var versionUpdateHostName = hostName
    var isAutoUpdate = false
    var debugGesture = true
    var manualControlNetwork = false
    var enableFileLog = false
    var enableRemoteLog = false
    var supportLocale: [SupportLocale] = [.Vietnam()]
}

private class QatConfig: Env {
    var internetProtocol = "https://"
    var hostName: [String: [String]] =
        [
            SupportLocale.China.shared.cultureCode(): ["qat1-app.affclub.xyz", "qat1-app2.affclub.xyz"],
            SupportLocale.Vietnam.shared
                .cultureCode(): ["qat1-app2.affclub.xyz", "qat1-app.affclub.xyz"],
        ]
    lazy var versionUpdateHostName = hostName
    var isAutoUpdate = false
    var debugGesture = true
    var manualControlNetwork = false
    var enableFileLog = true
    var enableRemoteLog = true
    var supportLocale: [SupportLocale] = [.China(), .Vietnam()]
}

private class StagingConfig: Env {
    var internetProtocol = "https://"
    var hostName: [String: [String]] =
        [
            SupportLocale.China.shared.cultureCode(): ["mobile.staging.support", "mobile2.staging.support"],
            SupportLocale.Vietnam.shared
                .cultureCode(): ["mobile2.staging.support", "mobile.staging.support"],
        ]
    lazy var versionUpdateHostName = hostName
    var isAutoUpdate: Bool {
        #if targetEnvironment(simulator)
            return false
        #else
            return true
        #endif
    }

    var debugGesture = true
    var manualControlNetwork = false
    var enableFileLog = true
    var enableRemoteLog = true
    var supportLocale: [SupportLocale] = [ .Vietnam()]
}

private class PreProductionConfig: Env {
    var internetProtocol = "https://"
    var hostName: [String: [String]] = [
        SupportLocale.China.shared.cultureCode(): ["kpp-app.ppsite.fun"],
        SupportLocale.Vietnam.shared.cultureCode(): ["kpp-appvnd.ppsite.fun"],
    ]
    lazy var versionUpdateHostName = hostName
    var isAutoUpdate = true
    var debugGesture = false
    var manualControlNetwork = false
    var enableFileLog = true
    var enableRemoteLog = true
    var supportLocale: [SupportLocale] = [ .Vietnam()]
}

private class ProductionConfig: Env {
    var internetProtocol = "https://"
    var hostName: [String: [String]] = [
        SupportLocale.China.shared.cultureCode(): ["appkto.com", "thekto.app"],
        SupportLocale.Vietnam.shared.cultureCode(): ["ktovn.app", "ktoviet.app"],
    ]
    var versionUpdateHostName: [String: [String]] =
        [
            SupportLocale.China.shared.cultureCode(): ["download5566.store", "downloadappgo5566.store"],
            SupportLocale.Vietnam.shared
                .cultureCode(): ["download5566.store", "downloadappgo5566.store"],
        ]
    var isAutoUpdate = true
    var debugGesture = false
    var manualControlNetwork = false
    var enableFileLog = false
    var enableRemoteLog = true
    var supportLocale: [SupportLocale] = [ .Vietnam()]
}

private class ProductionSelftestConfig: Env {
    var internetProtocol = "https://"
    var hostName: [String: [String]] = [
        SupportLocale.China.shared.cultureCode(): ["mobile-selftest.ktokto.net"],
        SupportLocale.Vietnam.shared.cultureCode(): ["mobile-selftest.ktokto.net"],
    ]
    var versionUpdateHostName: [String: [String]] =
        [
            SupportLocale.China.shared.cultureCode(): ["download5566.store", "downloadappgo5566.store"],
            SupportLocale.Vietnam.shared
                .cultureCode(): ["download5566.store", "downloadappgo5566.store"],
        ]
    var isAutoUpdate = false
    var debugGesture = true
    var manualControlNetwork = false
    var enableFileLog = true
    var enableRemoteLog = true
    var supportLocale: [SupportLocale] = [ .Vietnam()]
}

private class ProductionBackupConfig: Env {
    var internetProtocol = "https://"
    var hostName: [String: [String]] = [
        SupportLocale.China.shared.cultureCode(): ["thekto.app"],
        SupportLocale.Vietnam.shared.cultureCode(): ["ktoviet.app"],
    ]
    var versionUpdateHostName: [String: [String]] =
        [
            SupportLocale.China.shared.cultureCode(): ["download5566.store", "downloadappgo5566.store"],
            SupportLocale.Vietnam.shared
                .cultureCode(): ["download5566.store", "downloadappgo5566.store"],
        ]
    var isAutoUpdate = true
    var debugGesture = false
    var manualControlNetwork = false
    var enableFileLog = false
    var enableRemoteLog = true
    var supportLocale: [SupportLocale] = [ .Vietnam()]
}
