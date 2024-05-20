import Moya
import RxSwift
import UIKit
import WebKit

class CDNErrorViewController: WebViewBase {
    private var viewModel = Injectable.resolve(TermsViewModel.self)!
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .take(until: self.rx.deallocated)
            .subscribe(onNext: { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)

        viewModel.getCustomerServiceEmail
            .subscribe(onSuccess: { [weak self] _ in
                self?.dismiss(animated: true)
            }, onFailure: { [weak self] in
                if
                    $0.isCDNError(),
                    let data = ($0 as! MoyaError).response?.data,
                    let content = String(data: data, encoding: .utf8)
                {
                    self?.webView.loadHTMLString(content, baseURL: nil)
                }
                else {
                    self?.dismiss(animated: true)
                }
            })
            .disposed(by: disposeBag)
    }
}
