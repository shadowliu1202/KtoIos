import Foundation

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
    
    static var host: String         = env.host
    static var isAutoUpdate: Bool   = env.isAutoUpdate
    static var manualUpdate: Bool   = env.manualUpdate
    static var debugGesture: Bool   = env.debugGesture
    static var downloadUrl: URL     = env.downloadUrl
    static var affiliateUrl: URL    = URL(string: "\(env.host)affiliate")!
}

protocol Env {
    var host: String { get }
    var isAutoUpdate: Bool { get }
    var manualUpdate: Bool { get }
    var debugGesture: Bool { get }
    var downloadUrl: URL { get }
}

fileprivate class DevConfig: Env {
    var host: String = "https://qat1-mobile.affclub.xyz/"
    var isAutoUpdate: Bool = false
    var manualUpdate: Bool = true
    var debugGesture: Bool = true
    var downloadUrl: URL = URL(string: "https://www.google.com")!
}

fileprivate class QatConfig: Env {
    var host: String = "https://qat1-mobile.affclub.xyz/"
    var isAutoUpdate: Bool = false
    var manualUpdate: Bool = true
    var debugGesture: Bool = true
    var downloadUrl: URL = URL(string: "https://beta.itunes.apple.com/v1/app/1576526542")!
}

fileprivate class StagingConfig: Env {
    var host: String = "https://mobile.staging.support/"
    var isAutoUpdate: Bool = true
    var manualUpdate: Bool = false
    var debugGesture: Bool = false
    var downloadUrl: URL = URL(string: "https://stgtest.qdcmdq.com/")!
}
