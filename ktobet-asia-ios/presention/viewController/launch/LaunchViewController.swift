import UIKit
import RxSwift
import SharedBu

class LaunchViewController: UIViewController {
    private let viewModel = DI.resolve(NavigationViewModel.self)!
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.initLaunchNavigation()
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: executeNavigation, onError: handleErrors).disposed(by: disposeBag)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    override func handleErrors(_ error: Error) {
        if error.isMaintenance() {
            navigateToPortalMaintenancePage()
        } else if error.isCDNError() || error.isRestrictedArea() {
            super.handleErrors(error)
        } else {
            self.showAlert(Localize.string("common_error"), Localize.string("common_network_error"))
        }
    }
    
    private func showAlert(_ title: String?, _ message: String?) {
        Alert.show(title, message ,confirm: { exit(0) }, confirmText: Localize.string("common_confirm"), cancel: nil)
    }
    
    private func executeNavigation(navigation: NavigationViewModel.LobbyPageNavigation) {
        observeCustomerService()
        switch navigation {
        case .portalAllMaintenance:
            navigateToPortalMaintenancePage()
        case .notLogin:
            playVideo(onCompleted: navigateToLandingPage)
        case .playerDefaultProduct(let product):
            navigateToProductPage(product)
        case .alternativeProduct(let defaultProduct, let alternativeProduct):
            navigateToMaintainPage(defaultProduct)
            alertMaintenance(product: defaultProduct, onConfirm: {
                self.navigateToProductPage(alternativeProduct)
            })
        case .setDefaultProduct:
            navigateToSetDefaultProductPage()
        }
    }
    
    private func observeCustomerService() {
        CustomServicePresenter.shared.observeCustomerService().subscribe().disposed(by: disposeBag)
    }

    private func navigateToPortalMaintenancePage(){
        NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
    }
    
    private func playVideo(onCompleted: @escaping (() -> Void)) {
        let videoView = VideoView()
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil, using: { _ in onCompleted() })
        let videoURL = Bundle.main.url(forResource: "KTO", withExtension: "mp4")!
        self.view.addSubview(videoView, constraints: .fill())
        videoView.play(with: videoURL, fail: onCompleted)
    }
    
    private func navigateToLandingPage() {
        NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
    }
    
    private func navigateToProductPage(_ productType: ProductType) {
        NavigationManagement.sharedInstance.goTo(productType: productType)
    }
    
    private func navigateToMaintainPage(_ type: ProductType) {
        NavigationManagement.sharedInstance.goTo(productType: type, isMaintenance: true)
    }
    
    private func alertMaintenance(product: ProductType, onConfirm: @escaping (() -> Void)) {
        Alert.show(Localize.string("common_maintenance_notify"),
                   Localize.string("common_default_product_maintain_content", StringMapper.parseProductTypeString(productType: product)),
                   confirm: onConfirm, cancel: nil)
    }
    
    private func navigateToSetDefaultProductPage() {
        NavigationManagement.sharedInstance.goToSetDefaultProduct()
    }
}
