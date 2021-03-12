import UIKit
import WebKit
import share_bu

class DepositThirdPartWebViewController: UIViewController {
    static let segueIdentifier = "toThirdPartWebSegue"
    
    @IBOutlet private weak var webView: WKWebView!
    
    var transaction: DepositTransaction!
    var cashAmount: CashAmount!
    var remitter: DepositRequest.Remitter!
    
    fileprivate var viewModel = DI.resolve(DepositViewModel.self)!

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addCloseToBarButtonItem(vc: self, isShowAlert: false) {
            self.performSegue(withIdentifier: "unwindToDeposit", sender: nil)
        }
        
        let url = viewModel.getPaymentHost() + "?" + transaction.queryParameter(payAmount: cashAmount, remiiter: remitter)
        for cookie in self.viewModel.getCookies() {
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
        }
        
        let request = URLRequest(url: URL(string: url)!)
        webView.load(request)
    }
}
