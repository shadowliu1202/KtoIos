import WebKit

class WebViewSSLErrorLogger: NSObject, WKNavigationDelegate {
  func webView(_ webView: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
    handleSSLError(webView, error)
  }

  func webView(_ webView: WKWebView, didFail _: WKNavigation!, withError error: Error) {
    handleSSLError(webView, error)
  }

  private func handleSSLError(_: WKWebView, _ error: Error) {
    if
      let sslError = error as? URLError,
      sslError.code == .secureConnectionFailed ||
      sslError.code == .serverCertificateHasBadDate ||
      sslError.code == .serverCertificateUntrusted ||
      sslError.code == .serverCertificateHasUnknownRoot ||
      sslError.code == .serverCertificateNotYetValid ||
      sslError.code == .clientCertificateRejected ||
      sslError.code == .clientCertificateRequired
    {
      let currentTime = Date()
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
      let formattedTime = dateFormatter.string(from: currentTime)

      let errorString = getErrorDescription(for: sslError.code)

      let errorDescription = sslError.localizedDescription

      Logger.shared.error(
        sslError,
        customValues: [
          "time": formattedTime,
          "errorString": errorString,
          "errorDescription": errorDescription
        ])
    }
  }

  private func getErrorDescription(for errorCode: URLError.Code) -> String {
    switch errorCode {
    case .secureConnectionFailed:
      return "Secure connection failed."
    case .serverCertificateHasBadDate:
      return "SSL certificate has an invalid date."
    case .serverCertificateUntrusted:
      return "SSL certificate is untrusted."
    case .serverCertificateHasUnknownRoot:
      return "SSL certificate has an unknown root."
    case .serverCertificateNotYetValid:
      return "SSL certificate is not yet valid."
    case .clientCertificateRejected:
      return "Client certificate was rejected."
    case .clientCertificateRequired:
      return "Client certificate is required."
    default:
      return "Unknown error."
    }
  }
}
