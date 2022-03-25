import UIKit
import WebKit
import RxSwift
import SharedBu

class DepositCryptoViewController: APPViewController {
    
    @IBOutlet private weak var webView: WKWebView!
    
    static var segueIdentifier = "toCryptoWebView"
    
    var url: String?
    var updateUrl: SingleWrapper<HttpUrl>?
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
        
        let MockWebViewUserAgent = Configuration.getKtoAgent()
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1 \(MockWebViewUserAgent)"
        

        if let urlString = url, let urlHost = URL(string: urlString) {
            let request = URLRequest(url: urlHost)
            webView.load(request)
        } else if let displayId = displayId {
            //MARK: 等 withdrawl refactor 後移除
            viewModel.requestCryptoDepositUpdate(displayId: displayId).subscribe {[weak self] (url) in
                let request = URLRequest(url: URL(string: url)!)
                self?.webView.load(request)
            } onError: {[weak self] (error) in
                self?.handleErrors(error)
            }.disposed(by: disposeBag)
        } else if let updateUrl = updateUrl {
            Single.from(updateUrl).subscribe {[weak self] url in
                let request = URLRequest(url: URL(string: url.url)!)
                self?.webView.load(request)
            } onError: { error in
                self.handleErrors(error)
            }.disposed(by: disposeBag)
        }
    }
    
    @objc func close() {
        self.webView.evaluateJavaScript("window.sessionStorage.getItem('success')") {[weak self] (result, error) in
            if let resultString = result as? String, error == nil, resultString == "success" {
                NavigationManagement.sharedInstance.popToNotificationOrBack { [weak self] in
                    self?.performSegue(withIdentifier: "unwindToDeposit", sender: nil)
                }
            } else {
                let title = Localize.string("common_confirm_cancel_operation")
                let message = Localize.string("deposit_online_terminate")
                Alert.show(title, message) {
                    NavigationManagement.sharedInstance.popToNotificationOrBack { [weak self] in
                        self?.performSegue(withIdentifier: "unwindToDeposit", sender: nil)
                    }
                } cancel: {}
            }
        }
    }
}
