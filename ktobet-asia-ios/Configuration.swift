import Foundation
import UIKit

///reference: https://cocoacasts.com/tips-and-tricks-managing-build-configurations-in-xocde
enum Configuration: String {
    case dev
    case qat
    case staging
    case production
    
    static private let current: Configuration = {
#if DEV
        return .dev
#elseif QAT
        return .qat
#elseif STAGING
        return .staging
#elseif PRODUCTION
        return .production
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
        case .production:
            return ProductionConfig()
        }
    }()
    
    static var host: String         = "https://\(hostName)/"
    static var hostName: String     = env.hostName.first(where: checkNetwork) ?? env.hostName.first!
    static var disableSSL: Bool     = env.disableSSL
    static var isAutoUpdate: Bool   = env.isAutoUpdate
    static var manualUpdate: Bool   = env.manualUpdate
    static var debugGesture: Bool   = env.debugGesture
    static var affiliateUrl: URL    = URL(string: "\(host)affiliate")!
    static var isAllowedVN: Bool = current == .production ? false : env.isAllowedVN

    static private func checkNetwork(url: String) -> Bool {
        let group = DispatchGroup()
        group.enter()
        var isSuccess = false
        guard let url = URL(string: "https://\(url)") else {
            group.leave()
            return isSuccess
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        URLSession(configuration: .default)
            .dataTask(with: request) { (_, response, error) -> Void in
            guard error == nil else {
                print("Error:", error ?? "")
                isSuccess = false
                group.leave()
                return
            }

            guard (response as? HTTPURLResponse)?
                .statusCode == 200 else {
                isSuccess = false
                group.leave()
                return
            }

            isSuccess = true
            group.leave()
        }.resume()

        group.wait()
        return isSuccess
    }
    
    static func getKtoAgent() -> String {
        let userAgent = "kto-app-ios/\(UIDevice.current.systemVersion) APPv\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
        return userAgent
    }
}

protocol Env {
    var hostName: [String] { get }
    var disableSSL: Bool { get }
    var isAutoUpdate: Bool { get }
    var manualUpdate: Bool { get }
    var debugGesture: Bool { get }
    var isAllowedVN: Bool { get }
}

fileprivate class DevConfig: Env {
    var hostName: [String] = ["qat1-mobile.affclub.xyz"]
    var disableSSL: Bool = true
    var isAutoUpdate: Bool = false
    var manualUpdate: Bool = true
    var debugGesture: Bool = true
    var isAllowedVN: Bool = false
}

fileprivate class QatConfig: Env {
    var hostName: [String] = ["qat1-mobile.affclub.xyz", "qat1-mobile2.affclub.xyz"]
    var disableSSL: Bool = true
    var isAutoUpdate: Bool = false
    var manualUpdate: Bool = true
    var debugGesture: Bool = true
    var isAllowedVN: Bool = false
}

fileprivate class StagingConfig: Env {
    var hostName: [String] = ["mobile.staging.support", "mobile2.staging.support"]
    var disableSSL: Bool = false
    var isAutoUpdate: Bool = true
    var manualUpdate: Bool = false
    var debugGesture: Bool = false
    var isAllowedVN: Bool = false
}

fileprivate class ProductionConfig: Env {
    var hostName: [String] = ["appkto.com", "thekto.app"]
    var disableSSL: Bool = false
    var isAutoUpdate: Bool = true
    var manualUpdate: Bool = false
    var debugGesture: Bool = false
    var isAllowedVN: Bool = false
}
