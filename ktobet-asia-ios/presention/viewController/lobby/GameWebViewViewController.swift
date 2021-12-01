import UIKit
import RxSwift
import SharedBu
import WebKit

class GameWebViewViewController: UIViewController {
    
    var viewModel: ProductWebGameViewModelProtocol?
    private var disposeBag = DisposeBag()
    
    var gameId: Int32!
    var gameProduct: String! {
        return viewModel?.getGameProduct() ?? ""
    }
    
    lazy var backSiteOption1 = KtoURL.baseUrl.absoluteString + gameProduct
    let backSiteHost = "app.ktoasia.com"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .all
        let wkWebConfig = WKWebViewConfiguration()
        let webView = WKWebView(frame: self.view.bounds, configuration: wkWebConfig)
        let MockWebViewUserAgent = "kto-app-ios/\(UIDevice.current.systemVersion) APPv\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")"
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1 \(MockWebViewUserAgent)"
        self.view.addSubview(webView)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        let webPagePreferences = WKWebpagePreferences()
        webPagePreferences.allowsContentJavaScript = true
        webView.configuration.defaultWebpagePreferences = webPagePreferences
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.dataDetectorTypes = .all
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        webView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        webView.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 0).isActive = true
        webView.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: 0).isActive = true

        for cookie in HttpClient().getCookies() {
            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
        }
        
        viewModel?.createGame(gameId: gameId).subscribeOn(MainScheduler.instance).subscribe {(url) in
            guard let url = url else { return }
            let request = URLRequest(url: url)
            webView.load(request)
        } onError: {[weak self] (error) in
            Alert.show(nil, Localize.string("product_game_maintenance"), confirm: {
                self?.dismiss(animated: true, completion: nil)
            }, cancel: nil)
        }.disposed(by: disposeBag)
#if DEV
        let backBtn = UIButton(frame: .zero)
        backBtn.setImage(UIImage(named: "Back"), for: .normal)
        self.view.addSubview(backBtn, constraints: [.equal(\.leadingAnchor, offset: 0),
                                                    .equal(\.safeAreaLayoutGuide.topAnchor, offset: 0)])
        backBtn.constrain([.equal(\.widthAnchor, length: 40), .equal(\.heightAnchor, length: 40)])
        backBtn.rx.touchUpInside.bind(onNext: { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
#endif
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .portrait
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
}
