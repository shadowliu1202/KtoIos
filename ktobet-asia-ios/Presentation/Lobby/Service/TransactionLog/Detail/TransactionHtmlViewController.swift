import UIKit
import WebKit

class TransactionHtmlViewController: LobbyViewController {
  private var httpClient = Injectable.resolve(HttpClient.self)!
  var html: String!
  @IBOutlet weak var webView: WKWebView!
  @IBOutlet weak var titleLabel: UILabel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupNavigationView()
    
    let contents = buildUpHtml()
    webView.loadHTMLString(contents, baseURL: nil)
    webView.scrollView.isScrollEnabled = false
  }
  
  private func setupNavigationView() {
    titleLabel.text = Localize.string("common_transaction")
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
  }

  func buildUpHtml() -> String {
    guard let filePath = Bundle.main.path(forResource: "wager_template", ofType: "html")
    else { return "" }
    
    let template = try? String(contentsOfFile: filePath, encoding: .utf8)
    
    return String(format: template ?? "", httpClient.host.absoluteString, httpClient.host.absoluteString, html)
  }
}
