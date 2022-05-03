import Connectivity
import RxCocoa

@objc protocol NetworkStatusDisplay: AnyObject {
    @objc func networkDidConnected()
    @objc func networkDisConnected()
    @objc func networkRequestHandle(error: Error)
}

let Reachability = ReachabilityHandler.sharedInstance

final class ReachabilityHandler {
    private let connectivity: Connectivity = Connectivity()
    private var connected: (Connectivity) -> Void
    private var disconnected: (Connectivity) -> Void
    private(set) var requestErrorCallback: (Error) -> Void
    private let _didBecomeReachable = PublishRelay<Void>()
    var didBecomeConnected: Signal<Void> { return _didBecomeReachable.asSignal() }
    var isNetworkConnected = true
    
    private(set) static var sharedInstance: ReachabilityHandler?
    
    class func shared(connected: @escaping Connectivity.NetworkConnected, disconnected: @escaping Connectivity.NetworkDisconnected, requestError: @escaping (Error) -> Void) -> ReachabilityHandler {
        guard let instance = sharedInstance else {
            sharedInstance = ReachabilityHandler(connected: connected, disconnected: disconnected, requestErrorCallback: requestError)
            return sharedInstance!
        }
        return instance
    }
    
    private init(connected: @escaping Connectivity.NetworkConnected,
                 disconnected: @escaping Connectivity.NetworkDisconnected,
                 requestErrorCallback: @escaping (Error) -> Void) {
        self.connected = { (connectivity) in
            connectivity.isPollingEnabled = false
            Reachability?.isNetworkConnected = true
            connected(connectivity)
            Reachability?._didBecomeReachable.accept(())
            
        }
        self.disconnected = { (connectivity) in
            connectivity.isPollingEnabled = true
            Reachability?.isNetworkConnected = false
            disconnected(connectivity)
        }
        self.requestErrorCallback = { (error) in
            DispatchQueue.main.async {
                requestErrorCallback(error)
            }
        }
        configure()
    }
    
    func setForceCheck() {
        self.connectivity.isPollingEnabled = true
    }
    
    deinit {
        connectivity.stopNotifier()
    }
    
    private func configure() {
        connectivity.whenConnected = connected
        connectivity.whenDisconnected = disconnected
        connectivity.startNotifier()
    }
    
}
