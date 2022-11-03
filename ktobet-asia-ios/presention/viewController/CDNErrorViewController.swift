import UIKit
import RxSwift
import WebKit
import Moya

class CDNErrorViewController: UIViewController {
    
    private var viewModel = Injectable.resolve(TermsViewModel.self)!
    private var disposeBag = DisposeBag()
    private var webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification).takeUntil(self.rx.deallocated).subscribe(onNext: { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposeBag)
        setupWebView()
        viewModel.getCustomerServiceEmail.subscribe(onSuccess: { [weak self] _ in
            self?.dismiss(animated: true)
        }, onError: { [weak self] in
            if $0.isCDNError(),
               let data = ($0 as! MoyaError).response?.data,
               let content = String(data: data, encoding: .utf8) {
                self?.webView.loadHTMLString(content, baseURL: nil)
            } else {
                self?.dismiss(animated: true)
            }
        }).disposed(by: disposeBag)
    }
    
    private func setupWebView() {
        webView.scrollView.delegate = self
        webView.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        webView.isOpaque = false
        self.view.addSubview(webView, constraints: .fill())
    }

}

extension CDNErrorViewController: UIScrollViewDelegate {
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
}
