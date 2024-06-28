import Foundation
import SwiftSignalRClient

class KeepReconnectPolicy: ReconnectPolicy {
    private let timeInterval: DispatchTimeInterval
  
    init(timeInterval: DispatchTimeInterval) {
        self.timeInterval = timeInterval
    }
  
    func nextAttemptInterval(retryContext _: RetryContext) -> DispatchTimeInterval {
        timeInterval
    }
}
