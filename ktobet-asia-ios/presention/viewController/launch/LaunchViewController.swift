import UIKit
import RxSwift
import SharedBu

class LaunchViewController: APPViewController {
    private var viewModel = DI.resolve(LaunchViewModel.self)!
    private var serviceViewModel = DI.resolve(ServiceStatusViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.initLocale()
            .andThen(Observable.combineLatest(serviceViewModel.output.portalMaintenanceStatus.asObservable(), viewModel.checkIsLogged().asObservable()))
            .subscribe(onNext: { [weak self] (status, isLogged) in
                switch status {
                case is MaintenanceStatus.AllPortal:
                    self?.showPortalMaintenance()
                case is MaintenanceStatus.Product:
                    if isLogged {
                        self?.observeCustomerService()
                        self?.nextPage()
                    } else {
                        self?.displayVideo {
                            NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LoginNavigation")
                            self?.observeCustomerService()
                        }
                    }
                default:
                    break
                }
            }) { [weak self] error in
                if error.isMaintenance() {
                    self?.showPortalMaintenance()
                } else if error.isNetworkLost() {
                    self?.displayAlert(Localize.string("common_error"), Localize.string("common_network_error"))
                } else {
                    self?.handleErrors(error)
                }
            }.disposed(by: disposeBag)
    }
    
    override func networkDisconnectHandler() {
        self.displayAlert(Localize.string("common_error"), Localize.string("common_network_error"))
    }
    
    func displayAlert(_ title: String?, _ message: String?) {
        Alert.show(title, message ,confirm: {exit(0)}, confirmText: Localize.string("common_confirm"), cancel: nil)
    }
    
    private func nextPage() {
        let playerDefaultProduct = viewModel.loadPlayerInfo().compactMap{ $0.defaultProduct }.asObservable()
        playerDefaultProduct.bind(to: serviceViewModel.input.playerDefaultProductType).disposed(by: disposeBag)
        serviceViewModel.output.toNextPage.subscribe(onError: {[weak self] error in self?.handleErrors(error) }).disposed(by: disposeBag)
    }
    
    private func observeCustomerService() {
        CustomServicePresenter.shared.observeCustomerService().subscribe().disposed(by: disposeBag)
    }
    
    private func displayVideo(_ complete: (() -> Void)?) {
        let videoView = VideoView()
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil, using: { _ in
            complete?()
        })
        let videoURL = Bundle.main.url(forResource: "KTO", withExtension: "mp4")!
        self.view.addSubview(videoView, constraints: .fill())
        videoView.play(with: videoURL, fail: { complete?() })
    }
    
    private func showPortalMaintenance() {
        self.disposeBag = DisposeBag()
        DispatchQueue.main.async {
            let vc = UIStoryboard(name: "Maintenance", bundle: nil).instantiateViewController(withIdentifier: "PortalMaintenanceViewController")
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}
