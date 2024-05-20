import Foundation
import RxSwift
import sharedbu
import SwiftSignalRClient

class CSSignalRClient: CSEventSubject {
    private enum Target: String {
        case UserJoinAsync
        case SpeakingAsync
        case QueueNumberAsync
        case StopRoomAsync
        case MaintenanceAsync
    }
  
    private enum SendEvent: String {
        case PreviewMessage
    }
  
    private let token: String
    private let httpClient: HttpClient
    private let customerServiceProtocol: CustomerServiceProtocol

    private var observer: CSEventObserver?
    private var socketConnect: HubConnection?

    init(
        _ token: String,
        _ httpClient: HttpClient,
        _ customerServiceProtocol: CustomerServiceProtocol)
    {
        self.token = token
        self.httpClient = httpClient
        self.customerServiceProtocol = customerServiceProtocol
    }

    private func buildHubConnection() -> HubConnection? {
        guard
            let url = URL(
                string: httpClient.host.absoluteString
                    .replacingOccurrences(of: "\(Configuration.internetProtocol)", with: "wss://") + "chat-ws?access_token=" +
                    token)
        else {
            return nil
        }

        return HubConnectionBuilder(url: url)
            .withJSONHubProtocol()
            .withHttpConnectionOptions(configureHttpOptions: { option in
                option.skipNegotiation = true
            })
            .withLogging(minLogLevel: .warning)
            .withAutoReconnect(reconnectPolicy: KeepReconnectPolicy(timeInterval: .seconds(5)))
            .withHubConnectionDelegate(delegate: self)
            .build()
    }

    // MARK: CSEventSubject

    func start(observer: CSEventObserver) {
        self.observer = observer
        startSocket()
    }

    func close() {
        observer = nil
        socketConnect?.stop()
        socketConnect = nil
    }
  
    private func startSocket() {
        socketConnect?.stop()
        socketConnect = nil
    
        socketConnect = buildHubConnection()
        if let socketConnect {
            socketConnect.start()
        }
    
        subscribeHub()
    }
  
    private func subscribeHub() {
        self.socketConnect?.on(method: Target.QueueNumberAsync.rawValue, callback: { [weak self] in
            self?.observer?.onVisit(visitor: Waiting())
        })

        self.socketConnect?.on(method: Target.UserJoinAsync.rawValue, callback: { [weak self] in
            guard let self else { return }
            self.observer?.onVisit(visitor: Connected(self.httpClient))
        })

        self.socketConnect?.on(method: Target.SpeakingAsync.rawValue, callback: { [weak self] (bean: SpeakingAsyncBean) in
            self?.observer?.onVisit(visitor: ReceiveMessage(bean: bean))
        })

        self.socketConnect?.on(method: Target.StopRoomAsync.rawValue, callback: { [weak self] _ in
            self?.observer?.onVisit(visitor: Close())
        })

        self.socketConnect?.on(method: Target.MaintenanceAsync.rawValue, callback: { [weak self] _ in
            self?.observer?.onVisit(visitor: Maintenance())
        })
    }
  
    func typing(message: String) {
        let payload = ["text": message]
        socketConnect?.send(method: SendEvent.PreviewMessage.rawValue, payload)
    }
}

extension CSSignalRClient: HubConnectionDelegate {
    func connectionDidOpen(hubConnection _: HubConnection) {
        Logger.shared.info("CustomerService Socket Connection Open.")
    }

    func connectionDidFailToOpen(error: Error) {
        Logger.shared.error(error)
    }

    func connectionDidClose(error: Error?) {
        guard let error else { return }
        Logger.shared.error(error)
    }
  
    func connectionDidReconnect() {
        _ = Single.from(customerServiceProtocol.getQueueNumber())
            .map { $0.data }
            .subscribe(onSuccess: { [unowned self] in
                guard let currentQueueNumber = $0 else { return }
      
                if currentQueueNumber.intValue == 0 {
                    observer?.onVisit(visitor: Connected(httpClient))
                }
                else {
                    observer?.onVisit(visitor: Waiting(currentQueueNumber.intValue))
                }
            })
    }
}
