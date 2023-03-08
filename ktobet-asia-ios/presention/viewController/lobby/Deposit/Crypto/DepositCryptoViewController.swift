import RxSwift
import SharedBu
import UIKit
import WebKit

class DepositCryptoViewController: LobbyViewController {
  static var segueIdentifier = "toCryptoWebView"

  @IBOutlet private weak var webView: WKWebView!

  private let httpClient = Injectable.resolve(HttpClient.self)!
  private let disposeBag = DisposeBag()

  var url: String?

  override func viewDidLoad() {
    super.viewDidLoad()

    NavigationManagement.sharedInstance
      .addBarButtonItem(vc: self, barItemType: .close, action: #selector(close))

    httpClient
      .getCookies()
      .forEach {
        webView.configuration.websiteDataStore.httpCookieStore
          .setCookie($0, completionHandler: nil)
      }

    let webPagePreferences = WKWebpagePreferences()
    webPagePreferences.allowsContentJavaScript = true
    webView.configuration.defaultWebpagePreferences = webPagePreferences

    let MockWebViewUserAgent = Configuration.getKtoAgent()
    webView.customUserAgent =
      "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1 \(MockWebViewUserAgent)"

    if let urlString = url, let urlHost = URL(string: urlString) {
      let request = URLRequest(url: urlHost)
      webView.load(request)
    }
  }

  @objc
  func close() {
    webView
      .evaluateJavaScript("window.sessionStorage.getItem('success')") { [weak self] result, error in
        if
          let resultString = result as? String,
          error == nil,
          resultString == "success"
        {
          NavigationManagement.sharedInstance
            .popToNotificationOrBack { [weak self] in
              self?.performSegue(withIdentifier: "unwindToDeposit", sender: nil)
            }
        }
        else {
          let title = Localize.string("common_confirm_cancel_operation")
          let message = Localize.string("deposit_crypto_terminate")

          Alert.shared.show(
            title,
            message,
            confirm: {
              NavigationManagement.sharedInstance.popToNotificationOrBack { [weak self] in
                self?.performSegue(withIdentifier: "unwindToDeposit", sender: nil)
              }
            },
            cancel: { })
        }
      }
  }
}
