import UIKit
import RxSwift
import SharedBu
import WebKit

class GameWebViewViewController: UIViewController {
    private var httpClient = Injectable.resolve(HttpClient.self)!
    var barButtonItems: [UIBarButtonItem] = []
    var viewModel: ProductWebGameViewModelProtocol?
    weak var delegate: WebGameViewCallback?
    private var disposeBag = DisposeBag()
    
    var gameUrl: URL?
    var gameName: String = ""
    var gameProduct: String! {
        return viewModel?.getGameProduct() ?? ""
    }
    private let deposit: String = "deposit"
    lazy var backSiteOption = httpClient.host.absoluteString
    
    private let localStorageRepo = Injectable.resolve(LocalStorageRepository.self)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bind(position: .left, barButtonItems: .kto(.close))
        self.title = gameName
        CustomServicePresenter.shared.isInGameWebView = true
        (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .all
        let wkWebConfig = WKWebViewConfiguration()
        let webView = WKWebView(frame: self.view.bounds, configuration: wkWebConfig)
        if let defaultAgent = WKWebView().value(forKey: "userAgent") {
            let MockWebViewUserAgent = Configuration.getKtoAgent()
            webView.customUserAgent = "\(defaultAgent) Safari/604.1 \(MockWebViewUserAgent)"
        }
        self.view.addSubview(webView, constraints: .fill())
        webView.navigationDelegate = self
        webView.uiDelegate = self
        let webPagePreferences = WKWebpagePreferences()
        webPagePreferences.allowsContentJavaScript = true
        webView.configuration.defaultWebpagePreferences = webPagePreferences
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.dataDetectorTypes = .all
        webView.translatesAutoresizingMaskIntoConstraints = false

        for cookie in httpClient.getCookies() {
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
        }
        
        guard let url = gameUrl else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .portrait
        self.delegate?.gameDisappear()
        CustomServicePresenter.shared.isInGameWebView = false
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    override func handleErrors(_ error: Error) {
        if error is KtoGameUnderMaintenance {
            let productType = viewModel?.getGameProductType()
            if let productType = productType {
                Alert.shared.show(nil, Localize.string("product_game_maintenance"), confirm: {
                    NavigationManagement.sharedInstance.goTo(productType: productType)
                }, cancel: nil)
            } else {
                NavigationManagement.sharedInstance.goToSetDefaultProduct()
            }
        } else {
            super.handleErrors(error)
        }
    }
    
    func redirectCloseGame() {
        self.dismiss(animated: false, completion: nil)
    }
    
    func redirectNavigateToDeposit() {
        self.dismiss(animated: false, completion: {
            NavigationManagement.sharedInstance.sideBarViewController.cleanProductSelected()
            NavigationManagement.sharedInstance.goToDeposit()
        })
    }
}


extension GameWebViewViewController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString {
            if url == backSiteOption + gameProduct  {
                redirectCloseGame()
            } else if url == backSiteOption + deposit {
                redirectNavigateToDeposit()
            }
        }
    }
    
    /// Handles target=_blank links by opening them in the same view
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        if challenge.protectionSpace.host == httpClient.host.absoluteString {
            completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

extension GameWebViewViewController: BarButtonItemable {
    func pressedLeftBarButtonItems(_ sender: UIBarButtonItem) {
        self.navigationController?.dismiss(animated: true, completion: nil)
    }
}
