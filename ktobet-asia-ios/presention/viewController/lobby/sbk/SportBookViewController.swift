import NotificationBannerSwift
import RxRelay
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
  private lazy var localStorageRepo = Injectable.resolveWrapper(LocalStorageRepository.self)
  private lazy var playerViewModel = Injectable.resolveWrapper(PlayerViewModel.self)
  private lazy var serviceViewModel = Injectable.resolveWrapper(ServiceStatusViewModel.self)
  private lazy var sportBookViewModel = Injectable.resolveWrapper(SportBookViewModel.self)

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
    sportBookViewModel
      .observeMaintenanceStatus()
      .subscribe(onNext: { [weak self] status in
        guard let self else { return }

        switch status {
        case is MaintenanceStatus.AllPortal:
          self.playerViewModel.logout()
            .subscribe(onCompleted: {
              NavigationManagement.sharedInstance.goTo(
                storyboard: "Maintenance",
                viewControllerId: "PortalMaintenanceViewController")
            })
            .disposed(by: self.disposeBag)

        case let productStatus as MaintenanceStatus.Product:
          if productStatus.isProductMaintain(productType: .sbk) {
            NavigationManagement.sharedInstance.goTo(productType: .sbk, isMaintenance: true)
          }
        default:
          break
        }
      })
      .disposed(by: disposeBag)

    sportBookViewModel.errors()
      .subscribe(onNext: { [weak self] error in
        guard let self else { return }

        self.handleErrors(error)
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
  func webView(_: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
    print("test:Strat to load")
  }

  func webView(_: WKWebView, didReceiveServerRedirectForProvisionalNavigation _: WKNavigation!) {
    print("test:didReceiveServerRedirectForProvisionalNavigation")
  }

  func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
    print("test:\(error.localizedDescription)")
    isWebLoadSuccess.accept(false)
    self.activityIndicator.stopAnimating()
  }

  func webView(_: WKWebView, didCommit _: WKNavigation!) {
    print("test:>>>>>>didCommit")
  }

  func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
    print("test:\(error.localizedDescription)")
  }

  func webViewWebContentProcessDidTerminate(_: WKWebView) {
    print("test:webViewWebContentProcessDidTerminate")
  }

  func webView(_: WKWebView, didFinish _: WKNavigation!) {
    serviceViewModel.refreshProductStatus()
    print("test:didFinish")
    isWebLoadSuccess.accept(true)
    self.activityIndicator.stopAnimating()
  }

  func webView(
    _: WKWebView,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
  {
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
