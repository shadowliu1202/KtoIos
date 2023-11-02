import RxSwift
import sharedbu
import UIKit

class PortalMaintenanceViewController: LandingViewController {
  @IBOutlet weak var csEmailButton: UIButton!
  @IBOutlet weak var hourLabel: UILabel!
  @IBOutlet weak var minuteLabel: UILabel!
  @IBOutlet weak var secondLabel: UILabel!
  @IBOutlet var titleTextView: UITextView!

  private var viewModel = Injectable.resolve(ServiceStatusViewModel.self)!
  private var disposeBag = DisposeBag()
  private var email = ""
  private var countDownTimer = CountDownTimer()

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Change NavigationBar color when redirect from SearchViewController.
    Theme.shared.configNavigationBar(
      navigationController,
      backgroundColor: UIColor.greyScaleDefault.withAlphaComponent(0.9))

    initTitleTextViewAttributes(titleTextView)

    viewModel.output.customerServiceEmail
      .drive(onNext: { [weak self] email in
        self?.csEmailButton.setTitle(email, for: .normal)
      })
      .disposed(by: disposeBag)

    viewModel.output.portalMaintenanceStatusPerSecond.subscribe(onNext: { [weak self] status in
      switch status {
      case let allPortal as MaintenanceStatus.AllPortal:
        let seconds = allPortal.convertDurationToSeconds()?.int32Value
        self?.startCountDown(seconds: seconds)
      default:
        self?.navigateToLogin()
      }
    }).disposed(by: disposeBag)

    viewModel.refreshProductStatus()

    csEmailButton.rx.tap.subscribe(onNext: { [weak self] in
      guard let self else { return }
      if let url = URL(string: "mailto:\(self.email)") {
        if #available(iOS 10.0, *) {
          UIApplication.shared.open(url)
        }
        else {
          UIApplication.shared.openURL(url)
        }
      }
    }).disposed(by: disposeBag)
  }

  func initTitleTextViewAttributes(_ textView: UITextView) {
    textView.textContainerInset = .zero
    let suffix = Localize.string("common_kto")
    let maintenance = Localize.string("common_maintenance_description")
    let attributedText = NSAttributedString(text: maintenance)
      .color(.textPrimary)
      .font(UIFont(name: "PingFangSC-Semibold", size: 24)!)
      .color(.primaryDefault, for: suffix)
      .alignment(.center)
    textView.attributedText = attributedText
  }

  private func startCountDown(seconds: Int32?) {
    if let seconds, seconds > 0 {
      guard countDownTimer.isStart() == false else { return }
      countDownTimer.start(timeInterval: 1, duration: TimeInterval(seconds)) { [weak self] _, countDownSecond, finish in
        self?.displayRemainTimeView(countDownSecond)
        if finish {
          self?.navigateToLogin()
        }
      }
    }
    else {
      displayRemainTimeView(0)
    }
  }

  private func displayRemainTimeView(_ countDownSecond: Int) {
    self.hourLabel.text = String(format: "%02d", countDownSecond / 3600)
    self.minuteLabel.text = String(format: "%02d", (countDownSecond / 60) % 60)
    self.secondLabel.text = String(format: "%02d", countDownSecond % 60)
  }

  private func navigateToLogin() {
    NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}
