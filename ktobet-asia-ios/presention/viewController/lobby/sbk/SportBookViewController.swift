import UIKit
import RxSwift
import SharedBu
import WebKit
import SwiftUI
import NotificationBannerSwift
import RxRelay

class SportBookViewController: LobbyViewController {
    
    private let isWebLoadSuccess = BehaviorRelay<Bool>(value: false)
    
    private var webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    private var sbkWebUrlString: String { httpClient.host.absoluteString + "sbk" }
    private lazy var activityIndicator: UIActivityIndicatorView = {
        return UIActivityIndicatorView(style: .large)
    }()
    private var banner: NotificationBanner?
    
    private lazy var httpClient = DI.resolve(HttpClient.self)!
    private lazy var localStorageRepo: PlayerLocaleConfiguration = DI.resolve(LocalStorageRepositoryImpl.self)!
    private lazy var serviceViewModel = DI.resolve(ServiceStatusViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Logger.shared.info("\(type(of: self)) viewDidLoad.")
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: Localize.string("common_sportsbook"))
        self.view.addSubview(self.activityIndicator, constraints: [
            .equal(\.centerXAnchor),
            .equal(\.centerYAnchor)
        ])
        self.activityIndicator.startAnimating()
        self.setupWebView()
        
        serviceViewModel.output.portalMaintenanceStatus.subscribe(onNext: { status in
            switch status {
            case let product as MaintenanceStatus.Product:
                if product.isProductMaintain(productType: .sbk) {
                    NavigationManagement.sharedInstance.goTo(productType: .sbk, isMaintenance: true)
                }
            default:
                break
            }
        }, onError: { [weak self] error in
            self?.handleErrors(error)
        }).disposed(by: disposeBag)
        Observable.combineLatest(networkConnectRelay, isWebLoadSuccess).subscribe(onNext: { [unowned self] isNetworkConnected, isWebLoadSuccess in
            guard isWebLoadSuccess == false else { return }
            if isNetworkConnected {
                self.loadURL(webView: self.webView, urlString: self.sbkWebUrlString)
            }
        }).disposed(by: disposeBag)
        
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func setupWebView() {
        let MockWebViewUserAgent = Configuration.getKtoAgent()
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1 \(MockWebViewUserAgent)"
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
            print("test: cookie:\(cookie)")
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
        }
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.delegate = self
        webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -self.view.safeAreaInsets.bottom, right: 0)
        self.view.addSubview(webView, constraints: .fill())
    }
    
    private func loadURL(webView: WKWebView, urlString: String) {
        let url = URL(string: urlString)
        if let url = url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    private func getZoomDisableScript() -> WKUserScript {
        let source: String = "var meta = document.createElement('meta');" +
            "meta.name = 'viewport';" +
            "meta.content = 'width=device-width, initial-scale=1.0, maximum- scale=1.0, user-scalable=no';" +
            "var head = document.getElementsByTagName('head')[0];" + "head.appendChild(meta);"
        return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
}

extension SportBookViewController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("test:Strat to load")
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        print("test:didReceiveServerRedirectForProvisionalNavigation")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("test:\(error.localizedDescription)")
        isWebLoadSuccess.accept(false)
        self.activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("test:>>>>>>didCommit")
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("test:\(error.localizedDescription)")
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        print("test:webViewWebContentProcessDidTerminate")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        serviceViewModel.refreshProductStatus()
        print("test:didFinish")
        isWebLoadSuccess.accept(true)
        self.activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.host == httpClient.host.absoluteString {
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension SportBookViewController: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
}
