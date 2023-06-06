import Foundation

public protocol TransportDelegate: AnyObject {
  func transportDidOpen() -> Void
  func transportDidReceiveData(_ data: Data) -> Void
  func transportDidClose(_ error: Error?) -> Void
}
