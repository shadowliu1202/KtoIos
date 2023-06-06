import Foundation

/// Http Client protocol.
public protocol HttpClientProtocol {
  /// Sends a `GET` HTTP request.
  ///
  /// - parameter url: URL
  /// - parameter completionHandler: callback invoked after the HTTP request has been completed
  func get(url: URL, completionHandler: @escaping (HttpResponse?, Error?) -> Void)

  /// Sends a `POST` HTTP request with body data.
  ///
  /// - parameter url: URL
  /// - parameter body: Body data to send to server
  /// - parameter completionHandler: callback invoked after the HTTP request has been completed
  func post(url: URL, body: Data?, completionHandler: @escaping (HttpResponse?, Error?) -> Void)

  /// Sends a `DELETE` HTTP request.
  ///
  /// - parameter url: URL
  /// - parameter completionHandler: callback invoked after the HTTP request has been completed
  func delete(url: URL, completionHandler: @escaping (HttpResponse?, Error?) -> Void)
}
