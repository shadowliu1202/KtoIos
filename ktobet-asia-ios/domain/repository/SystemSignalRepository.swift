import Foundation
import RxSwift
import share_bu
import SwiftyJSON

protocol SystemSignalRepository {
    func connectService()
    func disconnectService()
    func subscribeEvent(target: Target)
    func observeSystemMessage() -> PublishSubject<Target>
}

class SystemSignalRepositoryImpl : SystemSignalRepository {
    private var socketConnect : HubConnection?
    private var httpClient : HttpClient!
    var observeMessage = PublishSubject<Target>()
    
    init(_ httpClient : HttpClient) {
        self.httpClient = httpClient
    }
    
    func connectService() {
        socketConnect?.stop()
        socketConnect = nil
        
        if let url = URL(string: "wss://qat1.pivotsite.com/notification-ws") {
            socketConnect = HubConnectionBuilder.init(url: url)
                .withJSONHubProtocol()
                .withHttpConnectionOptions(configureHttpOptions: { (option) in
                    option.skipNegotiation = true
                    option.headers["Cookie"] = self.httpClient.getToken()
                })
                .withLogging(minLogLevel: .debug)
                .withAutoReconnect()
                .build()
            
            socketConnect!.start()
        }
    }
    
    func subscribeEvent(target: Target) {
        socketConnect?.on(method: target.name, callback: { (arg) in
            switch target {
            case .Kickout:
                let type = try arg.getArgument(type: Int.self)
                self.observeMessage.onNext(Target.Kickout(KickOutType(rawValue: type)))
            case .Balance:
                print("")
            }
        })
    }
    
    func observeSystemMessage() -> PublishSubject<Target> {
        return observeMessage
    }
    
    func disconnectService() {
        socketConnect?.stop()
    }
}

public enum Target {
    case Balance
    case Kickout(_ kickOutType: KickOutType?)
    
    var name: String {
        switch self {
        case .Balance:
            return "Balance"
        case .Kickout:
            return "Kickout"
        }
    }
}

public enum KickOutType: Int {
    case duplicatedLogin = 1
    case Suspend = 2
    case Inactive = 3
    case Maintenance = 4
    case TokenExpired = 5
}
