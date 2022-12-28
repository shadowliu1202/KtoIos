import RxSwift
import Alamofire

protocol KtoURL {
    var baseUrl : [String : String]  {get}
}

extension KtoURL {
    func checkNetwork(urlString: String) -> Bool {
            let group = DispatchGroup()
            group.enter()
            var isSuccess = false
            guard let url = URL(string: "\(Configuration.internetProtocol)\(urlString)") else {
                group.leave()
                return isSuccess
            }

            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 4
            URLSession(configuration: configuration)
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
    
    private func request(session: Session, hostName: String) -> Single<Bool> {
        return RxSwift.Single<Bool>.create { observer in
            let request = session.request("\(Configuration.internetProtocol)\(hostName)/", method: .head).response { response in
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
    private lazy var hostName: [String: String] = Configuration.hostName
        .mapValues {
            Logger.shared.info("checkNetwork")
            return $0.first(where: checkNetwork) ?? $0.first!
        }
    lazy var baseUrl = hostName.mapValues{ "\(Configuration.internetProtocol)\($0)/" }
}

class VersionUpdateURL: KtoURL {
    private lazy var hostName: [String: String] = Configuration.versionUpdateHostName.mapValues{ $0.first(where: checkNetwork) ?? $0.first! }
    lazy var baseUrl = hostName.mapValues{ "\(Configuration.internetProtocol)\($0)/" }
}
