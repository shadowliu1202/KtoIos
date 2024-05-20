import RxSwift
import UIKit
import WebKit

class AffiliateViewController: WebViewBase {
    private let url: URL
    private let viewModel = Injectable.resolveWrapper(TermsViewModel.self)
    private let playerViewModel = Injectable.resolveWrapper(PlayerViewModel.self)
    private let disposeBag = DisposeBag()

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        webView.navigationDelegate = self
        webView.load(URLRequest(url: url))
    }

    override func setupUserAgent() { }

    override func setupCookies() { }

    deinit {
        print("\(type(of: self)) deinit")
    }
}

extension AffiliateViewController {
    private func redirectClose() {
        playerViewModel
            .checkIsLogged()
            .subscribe(
                onSuccess: { [weak self] isLogged in
                    if isLogged {
                        self?.dismiss(animated: false, completion: nil)
                    }
                    else {
                        self?.logoutToLanding()
                    }
                },
                onFailure: { [weak self] error in
                    if error.isUnauthorized() {
                        self?.logoutToLanding()
                    }
                    else {
                        self?.handleErrors(error)
                    }
                })
            .disposed(by: disposeBag)
    }

    private func logoutToLanding() {
        playerViewModel
            .logout()
            .subscribe(onCompleted: {
                NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
            })
            .disposed(by: disposeBag)
    }
}

extension AffiliateViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation _: WKNavigation!) {
        if let url = webView.url?.absoluteString {
            if url == httpClient.host.absoluteString {
                redirectClose()
            }
        }
    }
}
