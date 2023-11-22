import Combine
import Connectivity
import RxCocoa

enum NetworkStatus: Int {
  case connected
  case reconnected
  case disconnect
}

protocol INetworkMonitor {
  var status: Observable<NetworkStatus> { get }
}

final class NetworkStateMonitor: INetworkMonitor {
  static let shared = NetworkStateMonitor()

  private let connectivity = Connectivity()
  private let _networkStatus = BehaviorRelay<NetworkStatus?>(value: nil)

  var connectivityStatus: ConnectivityStatus {
    connectivity.status
  }

  var isNetworkConnected: Bool {
    switch _networkStatus.value {
    case .disconnect:
      return false
    default:
      return true
    }
  }
  
  var status: Observable<NetworkStatus> {
    _networkStatus.compactMap { $0 }.distinctUntilChanged()
  }

  private init() { }

  func startNotifier() {
    connectivity.whenConnected = { [weak self] connectivity in
      DispatchQueue.main.async {
        if self?.isNetworkConnected == false {
          self?._networkStatus.accept(.reconnected)
        }
        connectivity.isPollingEnabled = false
        self?._networkStatus.accept(.connected)
      }
    }

    connectivity.whenDisconnected = { [weak self] connectivity in
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
