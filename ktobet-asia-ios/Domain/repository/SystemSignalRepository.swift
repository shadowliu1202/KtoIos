import Foundation
import RxSwift
import SharedBu
import SwiftyJSON

protocol SystemSignalRepository {
    func connectService()
    func disconnectService()
    func subscribeEvent(target: Target)
    func observeSystemMessage() -> PublishSubject<Target>
}

class SystemSignalRepositoryImpl: SystemSignalRepository {
    private var socketConnect: HubConnection?
    private var httpClient: HttpClient!
    var observeMessage = PublishSubject<Target>()

    init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func connectService() {
        socketConnect?.stop()
        socketConnect = nil
        let url = httpClient.host.absoluteString
            .replacingOccurrences(of: "\(Configuration.internetProtocol)", with: "wss://") + "notification-ws"
        if let url = URL(string: url) {
            socketConnect = HubConnectionBuilder(url: url)
                .withJSONHubProtocol()
                .withHttpConnectionOptions(configureHttpOptions: { option in
                    option.skipNegotiation = true
                    option.headers["Cookie"] = self.httpClient.cookiesHeader
                })
                .withLogging(minLogLevel: .debug)
                .withAutoReconnect()
                .build()

            socketConnect!.start()
        }
    }

    func subscribeEvent(target: Target) {
        socketConnect?.on(method: target.name, callback: { arg in
            switch target {
            case .Kickout:
                let type = try arg.getArgument(type: Int.self)
                self.observeMessage.onNext(Target.Kickout(KickOutType(rawValue: type)))
            case .Balance:
                self.observeMessage.onNext(Target.Balance)
            case .Maintenance:
                self.observeMessage.onNext(Target.Maintenance)
            }
        })
    }

    func observeSystemMessage() -> PublishSubject<Target> {
        observeMessage
    }

    func disconnectService() {
        socketConnect?.stop()
        socketConnect = nil
    }
}

public enum Target {
    case Balance
    case Kickout(_ kickOutType: KickOutType?)
    case Maintenance

    var name: String {
        switch self {
        case .Balance:
            return "Balance"
        case .Kickout:
            return "Kickout"
        case .Maintenance:
            return "Maintenance"
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
