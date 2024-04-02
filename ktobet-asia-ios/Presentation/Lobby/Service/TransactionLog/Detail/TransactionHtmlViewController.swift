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
    
    Task { @MainActor in
      let contents = await buildUpHtml()
      webView.loadHTMLString(contents, baseURL: nil)
      webView.scrollView.isScrollEnabled = false
    }
  }
  
  private func setupNavigationView() {
    titleLabel.text = Localize.string("common_transaction")
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
  }

  func buildUpHtml() async -> String {
    guard
      let filePath = Bundle.main.path(forResource: "wager_template", ofType: "html"),
      let template = try? String(contentsOfFile: filePath, encoding: .utf8),
      let response = try? await httpClient.request(
        APITarget(
          baseUrl: httpClient.host,
          path: "brand/api/static-file/get-version",
          method: .get,
          task: .requestPlain,
          header: httpClient.headers)).value,
      let cssVersion = String(data: response.data, encoding: .utf8)
    else { return "" }
    
    return String(
      format: template,
      "\(httpClient.host.absoluteString)/brand/sbk.\(cssVersion).css",
      "\(httpClient.host.absoluteString)/brand/casino.\(cssVersion).css",
      html)
  }
}
