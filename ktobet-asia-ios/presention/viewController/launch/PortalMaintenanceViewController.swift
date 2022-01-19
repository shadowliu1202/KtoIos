import UIKit
import RxSwift
import SharedBu


class PortalMaintenanceViewController: APPViewController {
    @IBOutlet weak var csEmailButton: UIButton!
    @IBOutlet weak var hourLabel: UILabel!
    @IBOutlet weak var minuteLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    
    private var viewModel = DI.resolve(ServiceStatusViewModel.self)!
    private var disposeBag = DisposeBag()
    private var email: String = ""
    private var countDownTimer: CountDownTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.output.customerServiceEmail.subscribe {[weak self] email in
            self?.csEmailButton.setTitle(Localize.string("common_cs_email", email), for: .normal)
        }.disposed(by: disposeBag)

        viewModel.output.portalMaintenanceStatus.drive {[weak self] status in
            switch status {
            case let allPortal as MaintenanceStatus.AllPortal:
                self?.initCountDownTimer(secondsToPortalActive: allPortal.remainingSeconds)
            default:
                self?.showNavigation()
            }
        }.disposed(by: disposeBag)
        
        viewModel.refreshProductStatus()
        
        csEmailButton.rx.tap.subscribe(onNext: {[weak self] in
            guard let self = self else { return }
            if let url = URL(string: "mailto:\(self.email)") {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }).disposed(by: disposeBag)
    }
    
    private func initCountDownTimer(secondsToPortalActive: Int32) {
        if countDownTimer == nil {
            countDownTimer = CountDownTimer()
            countDownTimer?.start(timeInterval: 1, duration: TimeInterval(secondsToPortalActive)) {[weak self] (index, countDownSecond, finish) in
                self?.hourLabel.text = String(format: "%02d", (countDownSecond / 3600))
                self?.minuteLabel.text = String(format: "%02d", (countDownSecond / 60))
                self?.secondLabel.text = String(format: "%02d", (countDownSecond % 60))
                if countDownSecond == 0 {
                    self?.showNavigation()
                } else {
                    self?.viewModel.refreshProductStatus()
                }
            }
        }
    }
    
    private func showNavigation() {
        NavigationManagement.sharedInstance.goTo(storyboard: "Launch", viewControllerId: "LaunchViewController")
    }
}
