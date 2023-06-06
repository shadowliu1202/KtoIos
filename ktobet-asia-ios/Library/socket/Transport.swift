import Foundation

public protocol Transport: AnyObject {
  var delegate: TransportDelegate? { get set }
  func start(url: URL, options: HttpConnectionOptions) -> Void
  func send(data: Data, sendDidComplete: @escaping (_ error: Error?) -> Void)
  func close() -> Void
}

internal protocol TransportFactory {
  func createTransport(availableTransports: [TransportDescription]) throws -> Transport
}
