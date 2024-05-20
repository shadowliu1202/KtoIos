import RxSwift
import sharedbu
import UIKit
import WebKit

class DepositCryptoWebViewController: LobbyViewController {
    @Injected private var cookieManager: CookieManager
  
    private let webView = WKWebView()
    private let delegate = WebViewSSLErrorLogger()
    private let disposeBag = DisposeBag()

    let url: String?

    init(url: String?) {
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

        NavigationManagement.sharedInstance
            .addBarButtonItem(vc: self, barItemType: .close, action: #selector(close))

        for cooky in cookieManager.cookies {
            webView.configuration.websiteDataStore.httpCookieStore
                .setCookie(cooky, completionHandler: nil)
        }

        let webPagePreferences = WKWebpagePreferences()
        webPagePreferences.allowsContentJavaScript = true
        webView.configuration.defaultWebpagePreferences = webPagePreferences

        let MockWebViewUserAgent = Configuration.getKtoAgent()
        webView.customUserAgent =
            "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1 \(MockWebViewUserAgent)"

        webView.navigationDelegate = delegate

        if let urlString = url, let urlHost = URL(string: urlString) {
            let request = URLRequest(url: urlHost)
            webView.load(request)
        }
    }

    @objc
    func close() {
        webView
            .evaluateJavaScript("window.sessionStorage.getItem('success')") { result, error in
                if
                    let resultString = result as? String,
                    error == nil,
                    resultString == "success"
                {
                    NavigationManagement.sharedInstance.popToRootViewController()
                }
                else {
                    let title = Localize.string("common_confirm_cancel_operation")
                    let message = Localize.string("deposit_crypto_terminate")

                    Alert.shared.show(
                        title,
                        message,
                        confirm: {
                            NavigationManagement.sharedInstance.popToRootViewController()
                        },
                        cancel: { })
                }
            }
    }
}
