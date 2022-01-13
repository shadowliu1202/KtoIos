import UIKit
import RxSwift
import SharedBu
import WebKit

class SportBookViewController: UIViewController {
    private var sbkWebUrlString: String { KtoURL.baseUrl.absoluteString + "sbk" }
    private lazy var activityIndicator: UIActivityIndicatorView = {
        return UIActivityIndicatorView(style: .large)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self, title: Localize.string("common_sportsbook"))
        DispatchQueue.main.async {
            self.view.addSubview(self.activityIndicator, constraints: [
                .equal(\.centerXAnchor),
                .equal(\.centerYAnchor)
            ])
            self.activityIndicator.startAnimating()
        }
        DispatchQueue.main.async {
            self.setupWebView()
        }
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    private func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        let MockWebViewUserAgent = "kto-app-ios/\(UIDevice.current.systemVersion) APPv\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1 \(MockWebViewUserAgent)"
        let webPagePreferences = WKWebpagePreferences()
        webPagePreferences.allowsContentJavaScript = true
        webView.configuration.defaultWebpagePreferences = webPagePreferences
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.dataDetectorTypes = .all
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        for cookie in HttpClient().getCookies() {
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
        }
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.delegate = self
        webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: -self.view.safeAreaInsets.bottom, right: 0)
        self.view.addSubview(webView, constraints: .fill())
        self.loadURL(webView: webView, urlString: self.sbkWebUrlString)
    }
    
    private func loadURL(webView: WKWebView, urlString: String) {
        let url = URL(string: urlString)
        if let url = url {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}

extension SportBookViewController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
        self.activityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.activityIndicator.stopAnimating()
    }
}

extension SportBookViewController: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
}
