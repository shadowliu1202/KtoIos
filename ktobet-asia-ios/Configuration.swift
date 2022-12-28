import Foundation
import UIKit
import SharedBu

///reference: https://cocoacasts.com/tips-and-tricks-managing-build-configurations-in-xocde
enum Configuration: String {
    case dev
    case qat
    case staging
    case pre_prod
    case production
    case prod_selftest
    case prod_backup
    
    static private let current: Configuration = {
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
    static private let env: Env = {
        switch current {
        case .dev:
            return DevConfig()
        case .qat:
            return QatConfig()
        case .staging:
            return StagingConfig()
        case .pre_prod:
            return PreProductionConfig()
        case .production:
            return ProductionConfig()
        case .prod_selftest:
            return ProductionSelftestConfig()
        case .prod_backup:
            return ProductionBackupConfig()
        }
    }()

    static var internetProtocol: String                     = env.internetProtocol
    static var hostName: [String: [String]]                 = env.hostName
    static var versionUpdateHostName: [String: [String]]    = env.versionUpdateHostName
    static var isAutoUpdate: Bool                           = env.isAutoUpdate
    static var manualUpdate: Bool                           = env.manualUpdate
    static var debugGesture: Bool                           = env.debugGesture
    static var manualControlNetwork: Bool                   = env.manualControlNetwork
    static var enableFileLog: Bool                          = env.enableFileLog
    static var enableRemoteLog: Bool                        = env.enableRemoteLog

    static func getKtoAgent() -> String {
        let userAgent = "kto-app-ios/\(UIDevice.current.systemVersion) APPv\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(UIDevice.modelName))"
        return userAgent
    }
}

protocol Env {
    var internetProtocol: String { get }
    var hostName: [String: [String]] { get }
    var versionUpdateHostName: [String: [String]] { get }
    var isAutoUpdate: Bool { get }
    var manualUpdate: Bool { get }
    var debugGesture: Bool { get }
    var manualControlNetwork: Bool { get }
    var enableFileLog: Bool { get }
    var enableRemoteLog: Bool { get }
}

fileprivate class DevConfig: Env {
    var internetProtocol: String = "https://"
    var hostName: [String: [String]] = [SupportLocale.China.shared.cultureCode(): ["qat1-mobile.affclub.xyz"],
                                        SupportLocale.Vietnam.shared.cultureCode(): ["qat1-appvnd.affclub.xyz"]]
    lazy var versionUpdateHostName = hostName
    var isAutoUpdate: Bool = false
    var manualUpdate: Bool = true
    var debugGesture: Bool = true
    var manualControlNetwork: Bool = false
    var enableFileLog: Bool = false
    var enableRemoteLog: Bool = false
}

fileprivate class QatConfig: Env {
    var internetProtocol: String = "https://"
    var hostName: [String: [String]] = [SupportLocale.China.shared.cultureCode(): ["qat1-app.affclub.xyz", "qat1-appvnd.affclub.xyz"],
                                        SupportLocale.Vietnam.shared.cultureCode(): ["qat1-appvnd.affclub.xyz", "qat1-app.affclub.xyz"]]
    lazy var versionUpdateHostName = hostName
    var isAutoUpdate: Bool = false
    var manualUpdate: Bool = true
    var debugGesture: Bool = true
    var manualControlNetwork: Bool = false
    var enableFileLog: Bool = true
    var enableRemoteLog: Bool = true
}

fileprivate class StagingConfig: Env {
    var internetProtocol: String = "https://"
    var hostName: [String: [String]] = [SupportLocale.China.shared.cultureCode(): ["mobile.staging.support", "mobile2.staging.support"],
                                        SupportLocale.Vietnam.shared.cultureCode(): ["mobile2.staging.support", "mobile.staging.support"]]
    lazy var versionUpdateHostName = hostName
    var isAutoUpdate: Bool = true
    var manualUpdate: Bool = false
    var debugGesture: Bool = true
    var manualControlNetwork: Bool = false
    var enableFileLog: Bool = true
    var enableRemoteLog: Bool = true
}

fileprivate class PreProductionConfig: Env {
    var internetProtocol: String = "http://"
    var hostName: [String: [String]] = [SupportLocale.China.shared.cultureCode(): ["kpp-app.ppsite.fun"],
                                        SupportLocale.Vietnam.shared.cultureCode(): ["kpp-appvnd.ppsite.fun"]]
    lazy var versionUpdateHostName = hostName
    var isAutoUpdate: Bool = true
    var manualUpdate: Bool = false
    var debugGesture: Bool = false
    var manualControlNetwork: Bool = false
    var enableFileLog: Bool = true
    var enableRemoteLog: Bool = true
}

fileprivate class ProductionConfig: Env {
    var internetProtocol: String = "https://"
    var hostName: [String: [String]] = [SupportLocale.China.shared.cultureCode(): ["appkto.com", "thekto.app"],
                                        SupportLocale.Vietnam.shared.cultureCode(): ["ktovn.app", "ktoviet.app"]]
    var versionUpdateHostName: [String : [String]] = [SupportLocale.China.shared.cultureCode(): ["download5566.store", "downloadappgo5566.store"],
                                                      SupportLocale.Vietnam.shared.cultureCode(): ["download5566.store", "downloadappgo5566.store"]]
    var isAutoUpdate: Bool = true
    var manualUpdate: Bool = false
    var debugGesture: Bool = false
    var manualControlNetwork: Bool = false
    var enableFileLog: Bool = false
    var enableRemoteLog: Bool = true
}

fileprivate class ProductionSelftestConfig: Env {
    var internetProtocol: String = "https://"
    var hostName: [String: [String]] = [SupportLocale.China.shared.cultureCode(): ["mobile-selftest.ktokto.net"],
                                        SupportLocale.Vietnam.shared.cultureCode(): ["mobile-selftest.ktokto.net"]]
    var versionUpdateHostName: [String : [String]] = [SupportLocale.China.shared.cultureCode(): ["download5566.store", "downloadappgo5566.store"],
                                                      SupportLocale.Vietnam.shared.cultureCode(): ["download5566.store", "downloadappgo5566.store"]]
    var isAutoUpdate: Bool = false
    var manualUpdate: Bool = false
    var debugGesture: Bool = true
    var manualControlNetwork: Bool = false
    var enableFileLog: Bool = true
    var enableRemoteLog: Bool = true
}

fileprivate class ProductionBackupConfig: Env {
    var internetProtocol: String = "https://"
    var hostName: [String: [String]] = [SupportLocale.China.shared.cultureCode(): ["thekto.app"],
                                        SupportLocale.Vietnam.shared.cultureCode(): ["ktoviet.app"]]
    var versionUpdateHostName: [String : [String]] = [SupportLocale.China.shared.cultureCode(): ["download5566.store", "downloadappgo5566.store"],
                                                      SupportLocale.Vietnam.shared.cultureCode(): ["download5566.store", "downloadappgo5566.store"]]
    var isAutoUpdate: Bool = true
    var manualUpdate: Bool = false
    var debugGesture: Bool = false
    var manualControlNetwork: Bool = false
    var enableFileLog: Bool = false
    var enableRemoteLog: Bool = true
}
