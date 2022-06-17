import UIKit
import WebKit

class TransactionHtmlViewController: LobbyViewController {

    var html: String!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var closeBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let contents = buildUpHtml()
        webView.loadHTMLString(contents, baseURL: nil)
        webView.scrollView.isScrollEnabled = false
    }
    
    func buildUpHtml() -> String {
        do {
            guard let filePath = Bundle.main.path(forResource: "wager_template", ofType: "html") else {
                print("File reading error")
                return ""
            }
            let template =  try String(contentsOfFile: filePath, encoding: .utf8)
            return String(format: template, KtoURL.baseUrl.absoluteString, KtoURL.baseUrl.absoluteString, html)
        } catch {
            print("File reading error")
        }
        return ""
    }
    
    @IBAction func pressClose(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
