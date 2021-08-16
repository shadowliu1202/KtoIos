import UIKit
import WebKit
import SharedBu

class DepositThirdPartWebViewController: UIViewController {
    static let segueIdentifier = "toThirdPartWebSegue"
    
    @IBOutlet private weak var webView: WKWebView!
    
    var url: String!
    
    fileprivate var viewModel = DI.resolve(DepositViewModel.self)!

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addCloseToBarButtonItem(vc: self, isShowAlert: false) {
            self.performSegue(withIdentifier: "unwindToDeposit", sender: nil)
        }
        
        for cookie in HttpClient().getCookies() {
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
        }
        
        if let urlString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let urlHost = URL(string: urlString) {
            let request = URLRequest(url: urlHost)
            webView.load(request)
        }
    }
}
