import sharedbu
import UIKit
import WebKit

class DepositThirdPartWebViewController: LobbyViewController {
    @Injected private var cookieManager: CookieManager
  
    private var httpClient = Injectable.resolveWrapper(HttpClient.self)

    private let webView = WKWebView()
    private let delegate = WebViewSSLErrorLogger()

    let url: String

    init(url: String) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .close, action: #selector(close))

        for cookie in cookieManager.cookies {
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
        }
        let MockWebViewUserAgent = Configuration.getKtoAgent()
        webView
            .customUserAgent =
            "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1 \(MockWebViewUserAgent)"

        webView.navigationDelegate = delegate

        if
            let urlString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let urlHost = URL(string: urlString)
        {
            let request = URLRequest(url: urlHost)
            webView.load(request)
        }
    }

    @objc
    func close() {
        NavigationManagement.sharedInstance.popToRootViewController()
        showToast(Localize.string("common_request_submitted"), barImg: .success)
    }
}
