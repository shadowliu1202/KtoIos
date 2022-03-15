import Foundation
import UIKit

///reference: https://cocoacasts.com/tips-and-tricks-managing-build-configurations-in-xocde
enum Configuration: String {
    case dev
    case qat
    case staging
    
    static private let current: Configuration = {
#if DEV
        return .dev
#elseif QAT
        return .qat
#elseif STAGING
        return .staging
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
        }
    }()
    
    static var host: String         = "https://\(env.hostName)/"
    static var hostName: String     = env.hostName
    static var disableSSL: Bool     = env.disableSSL
    static var isAutoUpdate: Bool   = env.isAutoUpdate
    static var manualUpdate: Bool   = env.manualUpdate
    static var debugGesture: Bool   = env.debugGesture
    static var affiliateUrl: URL    = URL(string: "\(host)affiliate")!
    
    
    static func getKtoAgent() -> String {
        let userAgent = "kto-app-ios/\(UIDevice.current.systemVersion) APPv\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
        return userAgent
    }
}

protocol Env {
    var hostName: String { get }
    var disableSSL: Bool { get }
    var isAutoUpdate: Bool { get }
    var manualUpdate: Bool { get }
    var debugGesture: Bool { get }
}

fileprivate class DevConfig: Env {
    var hostName: String = "qat1-mobile.affclub.xyz"
    var disableSSL: Bool = true
    var isAutoUpdate: Bool = false
    var manualUpdate: Bool = true
    var debugGesture: Bool = true
}

fileprivate class QatConfig: Env {
    var hostName: String = "qat1-mobile.affclub.xyz"
    var disableSSL: Bool = true
    var isAutoUpdate: Bool = false
    var manualUpdate: Bool = true
    var debugGesture: Bool = true
}

fileprivate class StagingConfig: Env {
    var hostName: String = "mobile.staging.support"
    var disableSSL: Bool = false
    var isAutoUpdate: Bool = true
    var manualUpdate: Bool = false
    var debugGesture: Bool = false
}
