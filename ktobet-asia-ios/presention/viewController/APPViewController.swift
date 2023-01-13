import UIKit
import SwiftUI
import RxSwift

func methodPointer<T: AnyObject>(obj: T, method: @escaping (T) -> () -> Void) -> (() -> Void) {
    return { [unowned obj] in method(obj)() }
}

class APPViewController: UIViewController {
    private var banner: UIView?

    private let disposeBag = DisposeBag()
    
    let networkConnectRelay = BehaviorRelay<Bool>(value: true)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "\(type(of: self))"
        
        initNetworkConnectRelay()
        handleNetworkStatus()
    }
    
    func networkDidConnectedHandler() {
        dismissBanner()
    }

    func networkReConnectedHandler() {
        dismissBanner()
    }
    
    func networkDisconnectHandler() {
        displayBanner()
    }

    private func displayBanner() {
        guard banner == nil else { return }
        if let banner = UIHostingController(rootView: BannerView()).view {
            self.banner = banner
            banner.backgroundColor = .clear
            self.view.addSubview(banner)
            banner.snp.makeConstraints { [unowned self] make in
                make.width.equalToSuperview()
                make.height.equalTo(52)
                make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            }
        }
    }

    private func dismissBanner() {
        banner?.removeFromSuperview()
        banner = nil
    }
    
    private func initNetworkConnectRelay() {
        networkConnectRelay.accept(NetworkStateMonitor.shared.isNetworkConnected)
    }
    
    private func handleNetworkStatus() {
        NetworkStateMonitor.shared.listener
            .subscribe(onNext: { [weak self] in
                switch $0 {
                case .connected:
                    self?.networkDidConnectedHandler()
                case .reconnected:
                    self?.networkReConnectedHandler()
                case .disconnect:
                    self?.networkDisconnectHandler()
                }
            })
            .disposed(by: disposeBag)
    }
}

extension APPViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        
    }
}
