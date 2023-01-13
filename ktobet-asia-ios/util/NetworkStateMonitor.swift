import Connectivity
import RxCocoa

final class NetworkStateMonitor {
    
    enum Status {
        case connected
        case reconnected
        case disconnect
    }
    
    static let shared = NetworkStateMonitor()
    
    private let connectivity: Connectivity = Connectivity()
    private let _networkStatus = BehaviorRelay<Status?>(value: nil)
    
    var isNetworkConnected: Bool {
        switch _networkStatus.value {
        case .disconnect:
            return false
        default:
            return true
        }
    }
    
    var listener: Observable<Status> {
        return _networkStatus.compactMap { $0 }
    }
    
    private init() { }
    
    func startNotifier() {
        connectivity.whenConnected = { [weak self] (connectivity) in
            DispatchQueue.main.async {
                if self?.isNetworkConnected == false {
                    self?._networkStatus.accept(.reconnected)
                }
                connectivity.isPollingEnabled = false
                self?._networkStatus.accept(.connected)
            }
        }
        
        connectivity.whenDisconnected = { [weak self] (connectivity) in
            DispatchQueue.main.async {
                connectivity.isPollingEnabled = true
                self?._networkStatus.accept(.disconnect)
            }
        }
        
        connectivity.startNotifier(queue: DispatchQueue.global())
    }
    
    deinit {
        connectivity.stopNotifier()
    }
    
    func setForceCheck() {
        self.connectivity.isPollingEnabled = true
    }
    
    func setIsNetworkConnected(_ flag: Bool) {
        if flag {
            _networkStatus.accept(.connected)
        }
        else {
            _networkStatus.accept(.disconnect)
        }
    }
}
