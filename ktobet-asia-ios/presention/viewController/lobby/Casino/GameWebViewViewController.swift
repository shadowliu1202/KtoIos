import UIKit
import RxSwift
import share_bu
import WebKit

class GameWebViewViewController: UIViewController {
    
    private var viewModel = DI.resolve(CasinoViewModel.self)!
    private var disposeBag = DisposeBag()
    
    var gameId: Int32!
    var gameProduct: String!
    
    lazy var backSiteOption1 = KtoURL.baseUrl.absoluteString + gameProduct
    let backSiteHost = "app.ktoasia.com"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        (UIApplication.shared.delegate as! AppDelegate).restrictRotation = .all
        let wkWebConfig = WKWebViewConfiguration()
        let webView = WKWebView(frame: self.view.bounds, configuration: wkWebConfig)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.109 Safari/537.36"
        self.view.addSubview(webView)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.configuration.preferences.javaScriptEnabled = true
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
        
        viewModel.createGame(gameId: gameId).subscribeOn(MainScheduler.instance).subscribe {(url) in
            guard let url = url else { return }
            let request = URLRequest(url: url)
            webView.load(request)
        } onError: {[weak self] (error) in
            Alert.show(nil, Localize.string("product_game_maintenance"), confirm: {
                self?.dismiss(animated: true, completion: nil)
            }, cancel: nil)
        }.disposed(by: disposeBag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
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
