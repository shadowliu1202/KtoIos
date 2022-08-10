import Connectivity
import RxCocoa

@objc protocol NetworkStatusDisplay: AnyObject {
    @objc func networkDidConnected()
    @objc func networkDisConnected()
    @objc func networkRequestHandle(error: Error)
}

final class NetworkStateMonitor {
    static let shared = NetworkStateMonitor()
    
    struct Config {
        fileprivate var connected: () -> Void
        fileprivate var disconnected: () -> Void
        fileprivate var requestErrorCallback: (Error) -> Void
    }
    
    var didBecomeConnected: Signal<Void> { return _didBecomeReachable.asSignal() }

    private(set) var requestErrorCallback: (Error) -> Void
    private(set) var isNetworkConnected = true

    private static var config: Config?
    private var connected: (Connectivity) -> Void
    private var disconnected: (Connectivity) -> Void
    private let connectivity: Connectivity = Connectivity()
    private let _didBecomeReachable = PublishRelay<Void>()
    
    private init() {
        guard let config = NetworkStateMonitor.config else {
            fatalError("You must call setup before accessing NetworkStateMonitor.shared")
        }
        
        self.connected = { (connectivity) in
            connectivity.isPollingEnabled = false
            NetworkStateMonitor.shared.isNetworkConnected = true
            config.connected()
            NetworkStateMonitor.shared._didBecomeReachable.accept(())
        }
        
        self.disconnected = { (connectivity) in
            connectivity.isPollingEnabled = true
            NetworkStateMonitor.shared.isNetworkConnected = false
            config.disconnected()
        }
        
        self.requestErrorCallback = { (error) in
            DispatchQueue.main.async {
                config.requestErrorCallback(error)
            }
        }
        
        configure()
    }
    
    deinit {
        connectivity.stopNotifier()
    }
    
    static func setup(connected: @escaping () -> Void, disconnected: @escaping () -> Void, requestError: @escaping (Error) -> Void) {
        let config = Config(connected: connected, disconnected: disconnected, requestErrorCallback: requestError)
        NetworkStateMonitor.config = config
    }
    
    func setForceCheck() {
        self.connectivity.isPollingEnabled = true
    }
    
    func setIsNetworkConnected(_ flag: Bool) {
        isNetworkConnected = flag
    }

    private func configure() {
        connectivity.whenConnected = connected
        connectivity.whenDisconnected = disconnected
        connectivity.startNotifier()
    }
}
