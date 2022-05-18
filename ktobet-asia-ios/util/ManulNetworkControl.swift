import Foundation

class ManualNetworkControl {
    static let shared = ManualNetworkControl()
    private init() {}
    var isNetworkConnect: Bool = true
    var baseUrl : URL {
        if !isNetworkConnect {
            return URL(string: "https://")!
        }
        return URL(string: Configuration.host[Localize.getSupportLocale().cultureCode()]!)!
    }
}
