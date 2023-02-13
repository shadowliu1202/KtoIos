import Foundation
import RxSwift

protocol SignalRepository {
  func observeSystemSignal() -> Observable<any BackendSignal>
}

class SignalRepositoryImpl: SignalRepository {
  private let httpClient: HttpClient
  private let _observeSignal = PublishSubject<any BackendSignal>()

  private var socketConnection: HubConnection?

  init(httpClient: HttpClient) {
    self.httpClient = httpClient
  }

  deinit {
    socketConnection?.stop()
    Logger.shared.info("System message socket stop connection.")
  }

  func observeSystemSignal() -> RxSwift.Observable<BackendSignal> {
    if socketConnection == nil {
      setupService()
      Logger.shared.info("System message socket start connection.")
    }

    return _observeSignal.asObservable()
  }

  private func setupService() {
    connectService()
    subscribeEvent()
  }

  private func connectService() {
    let url = httpClient.host.absoluteString
      .replacingOccurrences(of: "\(Configuration.internetProtocol)", with: "wss://") + "notification-ws"
    
    if let url = URL(string: url) {
      socketConnection = HubConnectionBuilder(url: url)
        .withJSONHubProtocol()
        .withHttpConnectionOptions(configureHttpOptions: { option in
          option.skipNegotiation = true
          option.headers["Cookie"] = self.httpClient.cookiesHeader
        })
        .withLogging(minLogLevel: .debug)
        .withAutoReconnect()
        .build()

      socketConnection!.start()
    }
  }

  private func subscribeEvent() {
    subscribeMaintenanceEvent()
    subscribeKickOutEvent()
    subscribeBalanceEvent()
  }

  private func subscribeMaintenanceEvent() {
    for maintenanceSignal in MaintenanceSignal.allCases {
      socketConnection?.on(
        method: MaintenanceSignal.getName(maintenanceSignal),
        callback: { [weak self] arg in
          guard let self else { return }

          let timeRange = try arg.getArgument(type: MaintenanceSignal.TimeRange.self)

          switch maintenanceSignal {
          case .all:
            self._observeSignal.onNext(MaintenanceSignal.all(timeRange: timeRange))
          case .casino:
            self._observeSignal.onNext(MaintenanceSignal.casino(timeRange: timeRange))
          case .slot:
            self._observeSignal.onNext(MaintenanceSignal.slot(timeRange: timeRange))
          case .numberGame:
            self._observeSignal.onNext(MaintenanceSignal.numberGame(timeRange: timeRange))
          case .sbk:
            self._observeSignal.onNext(MaintenanceSignal.sbk(timeRange: timeRange))
          case .p2p:
            self._observeSignal.onNext(MaintenanceSignal.p2p(timeRange: timeRange))
          case .arcade:
            self._observeSignal.onNext(MaintenanceSignal.arcade(timeRange: timeRange))
          }
        })
    }
  }

  private func subscribeKickOutEvent() {
    socketConnection?.on(
      method: KickOutSignal.getName(nil),
      callback: { [weak self] arg in
        guard let self else { return }
        
        let type = (try? arg.getArgument(type: Int.self)) ?? 1
        
        self._observeSignal.onNext(KickOutSignal(rawValue: type) ?? KickOutSignal.duplicatedLogin)
      })
  }
  
  private func subscribeBalanceEvent() {
    socketConnection?.on(
      method: BalanceSignal.getName(nil),
      callback: { [weak self] _ in
        guard let self else { return }
        
        self._observeSignal.onNext(BalanceSignal())
      })
  }
}
