import UIKit
import RxSwift
import SharedBu

class LaunchViewController: LandingViewController {
    private var viewModel = DI.resolve(LaunchViewModel.self)!
    private var serviceViewModel = DI.resolve(ServiceStatusViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.initLocale().subscribe(onCompleted: { }).disposed(by: disposeBag)
        Observable.combineLatest(serviceViewModel.output.portalMaintenanceStatus.asObservable(), viewModel.checkIsLogged().asObservable())
            .subscribe(onNext: { [weak self] (status, isLogged) in
                switch status {
                case is MaintenanceStatus.AllPortal:
                    self?.setPortalMaintenance()
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
                    self?.setPortalMaintenance()
                } else {
                    self?.handleErrors(error)
                }
            }.disposed(by: disposeBag)
    }
    
    override func registerNetworkDisConnnectedHandler() -> (() -> ())? {
        return { [weak self] in
            self?.displayAlert(Localize.string("common_error"), Localize.string("common_network_error"))
        }
    }
    
    func displayAlert(_ title: String?, _ message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.backgroundColor = UIColor.white
        alert.view.layer.cornerRadius = 14
        alert.view.clipsToBounds = true
        let confirmAction = UIAlertAction(title: Localize.string("common_confirm"), style: .default) { (action) in
            exit(0)
        }
        confirmAction.setValue(UIColor.redForLightFull, forKey: "titleTextColor")
        alert.addAction(confirmAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func nextPage() {
        let playerDefaultProduct = viewModel.loadPlayerInfo().compactMap{ $0.defaultProduct }.asObservable()
        playerDefaultProduct.bind(to: serviceViewModel.input.playerDefaultProductType).disposed(by: disposeBag)
        serviceViewModel.output.toNextPage.subscribe(onError: {[weak self] error in self?.handleErrors(error) }).disposed(by: disposeBag)
    }
    
    private func observeCustomerService() {
        CustomServicePresenter.shared.observeCustomerService().observeOn(MainScheduler.asyncInstance).subscribe(onCompleted: {
            print("Completed")
        }).disposed(by: disposeBag)
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
    
    private func setPortalMaintenance() {
        DispatchQueue.main.async {
            let vc = UIStoryboard(name: "Maintenance", bundle: nil).instantiateViewController(withIdentifier: "PortalMaintenanceViewController")
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    override func abstracObserverUpdate() { }
}
