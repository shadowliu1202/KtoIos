import RxSwift
import SharedBu
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
        self?.navigateToLaunch()
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
    let txt = AttribTextHolder(text: maintenance)
      .addAttr((text: maintenance, type: .color, UIColor.gray9B9B9B))
      .addAttr((text: maintenance, type: .font, UIFont(name: "PingFangSC-Semibold", size: 24)!))
      .addAttr((text: suffix, type: .color, UIColor.redF20000))
      .addAttr((text: maintenance, type: .center, ""))
    txt.setTo(textView: textView)
  }

  private func startCountDown(seconds: Int32?) {
    if let seconds, seconds > 0 {
      guard countDownTimer.isStart() == false else { return }
      countDownTimer.start(timeInterval: 1, duration: TimeInterval(seconds)) { [weak self] _, countDownSecond, finish in
        self?.displayRemainTimeView(countDownSecond)
        if finish {
          self?.navigateToLaunch()
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

  private func navigateToLaunch() {
    NavigationManagement.sharedInstance.goTo(storyboard: "Launch", viewControllerId: "LaunchViewController")
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
}
