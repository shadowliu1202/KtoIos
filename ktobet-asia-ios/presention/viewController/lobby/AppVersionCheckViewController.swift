import UIKit
import RxSwift
import SharedBu

class AppVersionCheckViewController: APPViewController {
    private var appSyncDispose: Disposable?
    private var disposeBag = DisposeBag()
    private var serviceViewModel = DI.resolve(ServiceStatusViewModel.self)!
    private let playerViewModel = DI.resolve(PlayerViewModel.self)!
    private var productType: ProductType?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observerCompulsoryUpdate()
        observeSystemStatus()
    }
    
    func observerCompulsoryUpdate() {
        appSyncDispose = AppSynchronizeViewModel.shared.compulsoryupdate.compactMap({$0}).subscribe(onNext: {[weak self] _ in
            let _ = self?.playerViewModel.logout().subscribeOn(MainScheduler.instance).subscribe(onCompleted: {
                NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
            }, onError: {
                print($0)
            })
        })
    }
    
    private func observeSystemStatus() {
        serviceViewModel.output.portalMaintenanceStatus.drive(onNext: { [weak self] status in
            guard let self = self, let productType = self.productType else { return }
            switch status {
            case is MaintenanceStatus.AllPortal:
                self.playerViewModel.logout()
                    .subscribeOn(MainScheduler.instance)
                    .subscribe(onCompleted: { [weak self] in
                        self?.showLoginMaintenanAlert()
                    }).disposed(by: self.disposeBag)
            case let productStatus as MaintenanceStatus.Product:
                if productStatus.isProductMaintain(productType: productType) {
                    NavigationManagement.sharedInstance.goTo(productType: productType, isMaintenance: true)
                }
            default:
                break
            }
        }).disposed(by: disposeBag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appSyncDispose?.dispose()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

extension AppVersionCheckViewController: WebGameViewCallback {
    func gameDidDisappear(productType: ProductType?) {
        if Reachability?.isNetworkConnected == false {
            self.networkDisConnected()
        }
        AppSynchronizeViewModel.shared.syncAppVersion()
        
        self.productType = productType
        serviceViewModel.refreshProductStatus()
    }
}
