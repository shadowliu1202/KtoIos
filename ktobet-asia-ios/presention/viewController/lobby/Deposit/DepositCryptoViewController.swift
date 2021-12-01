import UIKit
import WebKit
import RxSwift

class DepositCryptoViewController: UIViewController {
    
    @IBOutlet private weak var webView: WKWebView!
    
    static var segueIdentifier = "toCryptoWebView"
    
    var url: String?
    var displayId: String?
    
    private var viewModel = DI.resolve(DepositViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .close, action: #selector(close))
        
        HttpClient().getCookies().forEach{ webView.configuration.websiteDataStore.httpCookieStore.setCookie($0, completionHandler: nil) }
        let webPagePreferences = WKWebpagePreferences()
        webPagePreferences.allowsContentJavaScript = true
        webView.configuration.defaultWebpagePreferences = webPagePreferences
        
        let MockWebViewUserAgent = "kto-app-ios/\(UIDevice.current.systemVersion) APPv\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1 \(MockWebViewUserAgent)"

        if let urlString = url, let urlHost = URL(string: urlString) {
            let request = URLRequest(url: urlHost)
            webView.load(request)
        } else {
            guard let displayId = displayId else { return }
            viewModel.requestCryptoDepositUpdate(displayId: displayId).subscribe {[weak self] (url) in
                let request = URLRequest(url: URL(string: url)!)
                self?.webView.load(request)
            } onError: {[weak self] (error) in
                self?.handleUnknownError(error)
            }.disposed(by: disposeBag)
        }
    }
    
    @objc func close() {
        self.webView.evaluateJavaScript("window.sessionStorage.getItem('success')") {[weak self] (result, error) in
            if let resultString = result as? String, error == nil, resultString == "success" {
                self?.performSegue(withIdentifier: "unwindToDeposit", sender: nil)
            } else {
                let title = Localize.string("common_confirm_cancel_operation")
                let message = Localize.string("deposit_online_terminate")
                Alert.show(title, message) {
                    self?.performSegue(withIdentifier: "unwindToDeposit", sender: nil)
                } cancel: {}
            }
        }
    }
}
