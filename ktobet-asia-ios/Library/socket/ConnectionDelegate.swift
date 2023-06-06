import Foundation

public protocol ConnectionDelegate: AnyObject {
  func connectionDidOpen(connection: Connection)
  func connectionDidFailToOpen(error: Error)
  func connectionDidReceiveData(connection: Connection, data: Data)
  func connectionDidClose(error: Error?)
  func connectionWillReconnect(error: Error)
  func connectionDidReconnect()
}

extension ConnectionDelegate {
  public func connectionWillReconnect(error _: Error) { }
  public func connectionDidReconnect() { }
}
