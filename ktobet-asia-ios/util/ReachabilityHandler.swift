import Connectivity
import RxCocoa

@objc protocol NetworkStatusDisplay: AnyObject {
    @objc func networkDidConnected()
    @objc func networkDisConnected()
}

let Reachability = ReachabilityHandler.sharedInstance

final class ReachabilityHandler {
    private let connectivity: Connectivity = Connectivity()
    private var connected: (Connectivity) -> Void
    private var disconnected: (Connectivity) -> Void
    private let _didBecomeReachable = PublishRelay<Void>()
    var didBecomeConnected: Signal<Void> { return _didBecomeReachable.asSignal() }
    weak var delegate: NetworkStatusDisplay?
    private(set) var isNetworkConnected = true
    
    private(set) static var sharedInstance: ReachabilityHandler?
    
    class func shared(connected: @escaping Connectivity.NetworkConnected, disconnected: @escaping Connectivity.NetworkDisconnected) -> ReachabilityHandler {
        guard let instance = sharedInstance else {
            sharedInstance = ReachabilityHandler(connected: connected, disconnected: disconnected)
            return sharedInstance!
        }
        return instance
    }
    
    private init(connected: @escaping Connectivity.NetworkConnected, disconnected: @escaping Connectivity.NetworkDisconnected) {
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
