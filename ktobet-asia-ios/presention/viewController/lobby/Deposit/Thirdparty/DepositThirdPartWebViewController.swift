import SharedBu
import UIKit
import WebKit

class DepositThirdPartWebViewController: LobbyViewController {
  private var httpClient = Injectable.resolve(HttpClient.self)!
  static let segueIdentifier = "toThirdPartWebSegue"

  @IBOutlet private weak var webView: WKWebView!

  var url: String!

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .close, action: #selector(close))

    for cookie in httpClient.getCookies() {
      webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
    }
    let MockWebViewUserAgent = Configuration.getKtoAgent()
    webView
      .customUserAgent =
      "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1 \(MockWebViewUserAgent)"

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
    self.performSegue(withIdentifier: "unwindToDeposit", sender: nil)
  }
}
