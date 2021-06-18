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
        NavigationManagement.sharedInstance.addCloseToBarButtonItem(vc: self, isShowAlert: false) {
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
        
        HttpClient().getCookies().forEach{ webView.configuration.websiteDataStore.httpCookieStore.setCookie($0, completionHandler: nil) }
        webView.configuration.preferences.javaScriptEnabled = true

        if let url = url {
            let request = URLRequest(url: URL(string: url)!)
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
}
