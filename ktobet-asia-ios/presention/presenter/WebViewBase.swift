import UIKit
import WebKit

class WebViewBase: UIViewController {
  private(set) var httpClient = Injectable.resolveWrapper(HttpClient.self)
  private(set) var webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupWebView(view: view)
  }
  
  func setupWebView(view: UIView) {
    if let defaultAgent = WKWebView().value(forKey: "userAgent") {
      let MockWebViewUserAgent = Configuration.getKtoAgent()
      webView.customUserAgent = "\(defaultAgent) Safari/604.1 \(MockWebViewUserAgent)"
    }
    
    for cookie in httpClient.getCookies() {
      webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
    }
    
    webView.scrollView.delegate = self
    webView.uiDelegate = self
    webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    webView.scrollView.showsVerticalScrollIndicator = false
    webView.isOpaque = false
    
    view.addSubview(webView, constraints: .fill())
  }
}

extension WebViewBase: WKUIDelegate {
  /// Handles target=_blank links by opening them in the same view
  func webView(
    _ webView: WKWebView,
    createWebViewWith _: WKWebViewConfiguration,
    for navigationAction: WKNavigationAction,
    windowFeatures _: WKWindowFeatures)
    -> WKWebView?
  {
    if navigationAction.targetFrame == nil {
      webView.load(navigationAction.request)
    }
    return nil
  }
}

extension WebViewBase: UIScrollViewDelegate {
  func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with _: UIView?) {
    scrollView.pinchGestureRecognizer?.isEnabled = false
  }
}
