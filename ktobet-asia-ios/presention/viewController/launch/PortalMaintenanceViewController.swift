import UIKit
import RxSwift
import SharedBu


class PortalMaintenanceViewController: APPViewController {
    @IBOutlet weak var csEmailButton: UIButton!
    @IBOutlet weak var hourLabel: UILabel!
    @IBOutlet weak var minuteLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet var titleTextView: UITextView!
    
    private var viewModel = DI.resolve(ServiceStatusViewModel.self)!
    private var disposeBag = DisposeBag()
    private var email: String = ""
    private var countDownTimer: CountDownTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initTitleTextViewAttributes(titleTextView)
        
        viewModel.output.customerServiceEmail.drive(onNext: {[weak self] email in
            self?.csEmailButton.setTitle(Localize.string("common_cs_email", email), for: .normal)
        }).disposed(by: disposeBag)

        viewModel.output.portalMaintenanceStatus.drive {[weak self] status in
            switch status {
            case let allPortal as MaintenanceStatus.AllPortal:
                self?.initCountDownTimer(secondsToPortalActive: allPortal.convertDurationToSeconds()?.int32Value ?? 0)
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
    
    func initTitleTextViewAttributes(_ textView: UITextView) {
        textView.textContainerInset = .zero
        let suffix = Localize.string("common_kto")
        let maintenance = Localize.string("product_maintenance_title", suffix)
        let txt = AttribTextHolder(text: maintenance)
            .addAttr((text: maintenance, type: .color, UIColor.textPrimaryDustyGray))
            .addAttr((text: maintenance, type: .font, UIFont.init(name: "PingFangSC-Semibold", size: 24)!))
            .addAttr((text: suffix, type: .color, UIColor.red))
            .addAttr((text: maintenance, type: .center, ""))
        txt.setTo(textView: textView)
    }
    
    private func initCountDownTimer(secondsToPortalActive: Int32) {
        if countDownTimer == nil {
            countDownTimer = CountDownTimer()
            countDownTimer?.start(timeInterval: 1, duration: TimeInterval(secondsToPortalActive)) {[weak self] (index, countDownSecond, finish) in
                self?.hourLabel.text = String(format: "%02d", (countDownSecond / 3600))
                self?.minuteLabel.text = String(format: "%02d", ((countDownSecond / 60) % 60))
                self?.secondLabel.text = String(format: "%02d", (countDownSecond % 60))
                if finish {
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
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}
