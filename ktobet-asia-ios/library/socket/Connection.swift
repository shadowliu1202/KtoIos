import Foundation

public protocol Connection {
  var delegate: ConnectionDelegate? { get set }
  var connectionId: String? { get }
  func start() -> Void
  func send(data: Data, sendDidComplete: @escaping (_ error: Error?) -> Void) -> Void
  func stop(stopError: Error?) -> Void
}
