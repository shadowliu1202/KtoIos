import RxSwift
import Alamofire

protocol KtoURL {
    var baseUrl : [String : String]  {get}
}

extension KtoURL {
    func checkNetwork(urlString: String) -> Bool {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 4
        let session = AlamofireSessionWithRetrier(configuration: configuration)
        let result = request(session: session, hostName: urlString).toBlocking()
        do{
            return try result.single()
        } catch {
            return false
        }
    }
    
    private func request(session: Session, hostName: String) -> Single<Bool> {
        return RxSwift.Single<Bool>.create { observer in
            let request = session.request("https://\(hostName)/", method: .head).response { response in
                switch response.result {
                case .success:
                    observer(.success(true))
                case let .failure(error):
                    observer(.success(false))
                    print("afRequestError:\(error)")
                }
            }
            return Disposables.create {
                request.cancel()
            }
        }
    }
}

class PortalURL: KtoURL {
    private lazy var hostName: [String: String] = Configuration.hostName.mapValues{ $0.first(where: checkNetwork) ?? $0.first! }
    lazy var baseUrl = hostName.mapValues{ "https://\($0)/" }
}

class VersionUpdateURL: KtoURL {
    private lazy var hostName: [String: String] = Configuration.versionUpdateHostName.mapValues{ $0.first(where: checkNetwork) ?? $0.first! }
    lazy var baseUrl = hostName.mapValues{ "https://\($0)/" }
}
