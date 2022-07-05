import Foundation

class ManualNetworkControl {
    static let shared = ManualNetworkControl()
    private var httpClient = DI.resolve(HttpClient.self)!
    private init() {}
    var isNetworkConnect: Bool = true
    var baseUrl : URL {
        if !isNetworkConnect {
            return URL(string: "https://")!
        }
        return httpClient.host
    }
}
