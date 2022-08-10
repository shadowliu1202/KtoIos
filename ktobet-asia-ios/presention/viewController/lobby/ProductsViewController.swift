import UIKit
import RxSwift
import SharedBu

class ProductsViewController: LobbyViewController {
    private var disposeBag = DisposeBag()
    private var serviceViewModel = DI.resolve(ServiceStatusViewModel.self)!
    private let playerViewModel = DI.resolve(PlayerViewModel.self)!
    private var productType: ProductType?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        observeSystemStatus()
    }

    private func observeSystemStatus() {
        serviceViewModel.output.portalMaintenanceStatus.subscribe(onNext: { [weak self] status in
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

    func gameDidDisappear() {
        if NetworkStateMonitor.shared.isNetworkConnected == false {
            self.networkDisConnected()
        }
        syncAppVersionUpdate(versionSyncDisposeBag)
        serviceViewModel.refreshProductStatus()
    }
    
    func goToWebGame(viewModel: ProductWebGameViewModelProtocol, gameId: Int32, gameName: String) {
        viewModel.createGame(gameId: gameId).subscribeOn(MainScheduler.instance).subscribe { (url) in
            let storyboard = UIStoryboard(name: "Product", bundle: nil)
            let navi = storyboard.instantiateViewController(withIdentifier: "GameNavigationViewController") as! UINavigationController
            if let gameVc = navi.viewControllers.first as? GameWebViewViewController {
                gameVc.gameUrl = url
                gameVc.gameName = gameName
                gameVc.viewModel = viewModel
                gameVc.delegate = self
                navi.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
                self.present(navi, animated: true, completion: nil)
            }
        } onError: { [weak self] in
            self?.handleErrors($0)
        }.disposed(by: disposeBag)
    }
    
    override func handleErrors(_ error: Error) {
        if error is KtoGameUnderMaintenance {
            Alert.show(nil, Localize.string("product_game_maintenance"), confirm: {}, cancel: nil)
        } else {
            super.handleErrors(error)
        }
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

extension ProductsViewController: WebGameViewCallback {
    func gameDidDisappear(productType: ProductType?) {
        self.productType = productType
        self.gameDidDisappear()
    }
}
