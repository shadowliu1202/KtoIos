import UIKit
import RxSwift
import SharedBu
import WebKit

class GameWebViewViewController: UIViewController {
    var barButtonItems: [UIBarButtonItem] = []
    var viewModel: ProductWebGameViewModelProtocol?
    weak var delegate: WebGameViewCallback?
    private var disposeBag = DisposeBag()
    
    var gameId: Int32!
    var gameName: String = ""
    var gameProduct: String! {
        return viewModel?.getGameProduct() ?? ""
    }
    
    lazy var backSiteOption1 = KtoURL.baseUrl.absoluteString + gameProduct
    let backSiteHost = "app.ktoasia.com"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bind(position: .left, barButtonItems: .kto(.close))
        self.title = gameName
        CustomServicePresenter.shared.hiddenServiceIcon()
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

        for cookie in HttpClient().getCookies() {
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
        }
        
        viewModel?.createGame(gameId: gameId).subscribeOn(MainScheduler.instance).subscribe { (url) in
            guard let url = url else { return }
            let request = URLRequest(url: url)
            webView.load(request)
        } onError: { [weak self] in
            self?.handleErrors($0)
        }.disposed(by: disposeBag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .portrait
        self.delegate?.gameDidDisappear(productType: viewModel?.getGameProductType())
        CustomServicePresenter.shared.showServiceIcon()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    override func handleErrors(_ error: Error) {
        if error is KtoGameUnderMaintenance {
            let productType = viewModel?.getGameProductType()
            Alert.show(nil, Localize.string("product_game_maintenance"), confirm: {
                NavigationManagement.sharedInstance.goTo(productType: productType)
            }, cancel: nil)
        } else {
            super.handleErrors(error)
        }
    }
}


extension GameWebViewViewController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if let url = webView.url?.absoluteString, let host = webView.url?.host {
            if url == backSiteOption1 || url == "HTTPS://\(backSiteHost)/" + gameProduct || host == backSiteHost {
                self.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.host == Configuration.host[Localize.getSupportLocale().cultureCode()]! {
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
