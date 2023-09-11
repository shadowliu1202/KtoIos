import NotificationBannerSwift
import RxSwift
import SharedBu
import SwiftUI
import UIKit
import WebKit

class SportBookViewController: LobbyViewController {
  private let isWebLoadSuccess = BehaviorRelay<Bool>(value: false)

  private var webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
  private var sbkWebUrlString: String { httpClient.host.absoluteString + "sbk" }
  private lazy var activityIndicator = UIActivityIndicatorView(style: .large)

  private var banner: NotificationBanner?

  private lazy var httpClient = Injectable.resolveWrapper(HttpClient.self)
  private lazy var maintenanceViewModel = Injectable.resolveWrapper(MaintenanceViewModel.self)

  private var disposeBag = DisposeBag()

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    Logger.shared.info("\(type(of: self)) viewDidLoad.")

    NavigationManagement.sharedInstance
      .addMenuToBarButtonItem(vc: self, title: Localize.string("common_sportsbook"))

    view.addSubview(
      self.activityIndicator,
      constraints: [
        .equal(\.centerXAnchor),
        .equal(\.centerYAnchor)
      ])

    activityIndicator.startAnimating()
    setupWebView()

    binding()
  }

  private func setupWebView() {
    let MockWebViewUserAgent = Configuration.getKtoAgent()
    webView
      .customUserAgent =
      "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1 \(MockWebViewUserAgent)"
    let webPagePreferences = WKWebpagePreferences()
    webPagePreferences.allowsContentJavaScript = true
    webView.configuration.defaultWebpagePreferences = webPagePreferences
    webView.configuration.allowsInlineMediaPlayback = true
    webView.configuration.dataDetectorTypes = .all
    webView.configuration.userContentController.addUserScript(self.getZoomDisableScript())
    webView.translatesAutoresizingMaskIntoConstraints = false
    webView.scrollView.showsVerticalScrollIndicator = false
    webView.allowsBackForwardNavigationGestures = true
    webView.isOpaque = false
    for cookie in httpClient.getCookies() {
      webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
    }
    webView.navigationDelegate = self
    webView.uiDelegate = self
    webView.scrollView.delegate = self
    webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -self.view.safeAreaInsets.bottom, right: 0)
    self.view.addSubview(webView, constraints: .fill())
  }

  private func binding() {
    maintenanceViewModel.productMaintenanceStatus
      .drive(onNext: { productStatus in
        guard productStatus.isProductMaintain(productType: .sbk) else { return }
        
        let sbkMaintenanceNC = UIStoryboard(name: "Maintenance", bundle: nil)
          .instantiateViewController(withIdentifier: "SBKMaintenance") as! UINavigationController
        
        self.navigationController?.viewControllers = [sbkMaintenanceNC.topViewController!]
      })
      .disposed(by: disposeBag)

    Observable
      .combineLatest(
        networkConnectRelay,
        isWebLoadSuccess)
      .subscribe(onNext: { [unowned self] isNetworkConnected, isWebLoadSuccess in
        guard isWebLoadSuccess == false else { return }
        if isNetworkConnected {
          self.loadURL(webView: self.webView, urlString: self.sbkWebUrlString)
        }
      })
      .disposed(by: disposeBag)
  }

  private func loadURL(webView: WKWebView, urlString: String) {
    let url = URL(string: urlString)
    if let url {
      let request = URLRequest(url: url)
      webView.load(request)
    }
  }

  private func getZoomDisableScript() -> WKUserScript {
    let source = "var meta = document.createElement('meta');" +
      "meta.name = 'viewport';" +
      "meta.content = 'width=device-width, initial-scale=1.0, maximum- scale=1.0, user-scalable=no';" +
      "var head = document.getElementsByTagName('head')[0];" + "head.appendChild(meta);"
    return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
  }
}

extension SportBookViewController: WKNavigationDelegate, WKUIDelegate {
  func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
    Logger.shared.info("\(String(describing: webView.url)) start to loading")
  }

  func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation _: WKNavigation!) {
    Logger.shared.info("\(String(describing: webView.url)) did receive server redirect")
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
    Logger.shared.debug("\(String(describing: webView.url)) did fail navigation with \(error.localizedDescription)")
    isWebLoadSuccess.accept(false)
    self.activityIndicator.stopAnimating()
  }

  func webView(_ webView: WKWebView, didCommit _: WKNavigation!) {
    Logger.shared.info("\(String(describing: webView.url)) did commit")
  }

  func webView(_ webView: WKWebView, didFail _: WKNavigation!, withError error: Error) {
    Logger.shared.debug("\(String(describing: webView.url)) did fail with \(error.localizedDescription)")
  }

  func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
    Logger.shared.info("\(String(describing: webView.url)) did terminate")
  }

  func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
    Task { await maintenanceViewModel.pullMaintenanceStatus() }
    Logger.shared.info("\(String(describing: webView.url)) did finish")
    isWebLoadSuccess.accept(true)
    self.activityIndicator.stopAnimating()
  }

  func webView(
    _ webView: WKWebView,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
  {
    Logger.shared.info("\(String(describing: webView.url)) did receive challenge \(challenge.protectionSpace.host)")
    if challenge.protectionSpace.host == httpClient.host.absoluteString {
      completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    else {
      completionHandler(.performDefaultHandling, nil)
    }
  }
}

extension SportBookViewController: UIScrollViewDelegate {
  func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with _: UIView?) {
    scrollView.pinchGestureRecognizer?.isEnabled = false
  }
}
