import RxSwift
import sharedbu
import UIKit
import WebKit

class GameWebViewViewController: WebViewBase {
    var barButtonItems: [UIBarButtonItem] = []
    var viewModel: ProductWebGameViewModelProtocol?
    weak var delegate: WebGameViewCallback?
    private var disposeBag = DisposeBag()

    var gameUrl: URL?
    var gameName = ""
    var gameProduct: String! {
        viewModel?.getGameProduct() ?? ""
    }

    private let deposit = "deposit"

    private let localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.bind(position: .left, barButtonItems: .kto(.close))
        self.title = gameName
        CustomServicePresenter.shared.setFloatIconAvailable(false)
        (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .all

        webView.navigationDelegate = self
        let webPagePreferences = WKWebpagePreferences()
        webPagePreferences.allowsContentJavaScript = true
        webView.configuration.defaultWebpagePreferences = webPagePreferences
        webView.configuration.dataDetectorTypes = .all
        webView.translatesAutoresizingMaskIntoConstraints = false

        guard let url = gameUrl else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .portrait
        CustomServicePresenter.shared.setFloatIconAvailable(true)
    }
  
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.gameDisappear()
    }

    override func handleErrors(_ error: Error) {
        if error is KtoGameUnderMaintenance {
            let productType = viewModel?.getGameProductType()
            if let productType {
                Alert.shared.show(nil, Localize.string("product_game_maintenance"), confirm: {
                    NavigationManagement.sharedInstance.goTo(productType: productType)
                }, cancel: nil)
            }
            else {
                NavigationManagement.sharedInstance.goToSetDefaultProduct()
            }
        }
        else {
            super.handleErrors(error)
        }
    }

    func redirectCloseGame() {
        self.dismiss(animated: false, completion: nil)
    }

    func redirectNavigateToDeposit() {
        self.dismiss(animated: false, completion: {
            NavigationManagement.sharedInstance.sideBarViewController.cleanProductSelected()
            NavigationManagement.sharedInstance.goTo(storyboard: "Deposit", viewControllerId: "DepositNavigation")
        })
    }
}

extension GameWebViewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        let backSiteOption = httpClient.host.absoluteString
        if let url = webView.url?.absoluteString {
            if url == backSiteOption + gameProduct {
                redirectCloseGame()
            }
            else if url == backSiteOption + deposit {
                redirectNavigateToDeposit()
            }
        }
    }
  
    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        let SSLAndTSPRelatedErrorCode = [
            NSURLErrorAppTransportSecurityRequiresSecureConnection,
            NSURLErrorSecureConnectionFailed,
            NSURLErrorServerCertificateHasBadDate,
            NSURLErrorServerCertificateUntrusted,
            NSURLErrorServerCertificateHasUnknownRoot,
            NSURLErrorServerCertificateNotYetValid,
            NSURLErrorClientCertificateRejected,
            NSURLErrorClientCertificateRequired
        ]
    
        let nsError = error as NSError
        if
            nsError.domain == NSURLErrorDomain,
            SSLAndTSPRelatedErrorCode.contains(nsError.code),
            let failingURL = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL
        {
            showOpenExternalWebsiteAlert(url: failingURL)
        }
    }
  
    private func showOpenExternalWebsiteAlert(url: URL) {
        Alert.shared.show(
            Localize.string("common_tip_title_warm"),
            Localize.string("common_web_view_ssl_alert"),
            confirm: {
                UIApplication.shared.open(url)
            },
            cancel: { })
    }
  
    func webView(
        _: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        if challenge.protectionSpace.host == httpClient.host.absoluteString {
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        }
        else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension GameWebViewViewController: BarButtonItemable {
    func pressedLeftBarButtonItems(_: UIBarButtonItem) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}
