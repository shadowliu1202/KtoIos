import RxSwift
import SharedBu
import UIKit

class MaintenanceViewController: LobbyViewController {
  var serviceViewModel = Injectable.resolve(ServiceStatusViewModel.self)!
  private var productType: ProductType!
  var disposeBag = DisposeBag()
  private var timer: CountDownTimer?

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
    productType = ProductType.convert(self.view.tag)
    getMaintainRemainTime()
  }
  
  deinit {
    self.timer?.stop()
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func getMaintainRemainTime() {
    Observable.just(productType).bind(to: serviceViewModel.input.playerDefaultProductType).disposed(by: disposeBag)
    serviceViewModel.output.productMaintainTime.drive(onNext: { [weak self] time in
      guard let self else { return }
      if time != nil {
        self.updateTimelabels(time!)
      }
      else {
        NavigationManagement.sharedInstance.goTo(productType: self.productType)
      }
    }).disposed(by: disposeBag)
  }

  private func updateTimelabels(_ endTime: OffsetDateTime) {
    let remainTime = TimeInterval(endTime.epochSeconds - Int64(Date().timeIntervalSince1970))
    if self.timer == nil {
      self.timer = CountDownTimer()
    }
    self.timer?.start(timeInterval: 1, duration: remainTime) { [weak self] _, countdownseconds, finish in
      guard let self else { return }
      if finish {
        NavigationManagement.sharedInstance.goTo(productType: self.productType)
      }
      else {
        self.setTextPerSecond(countdownseconds)
      }
    }
  }

  public func setTextPerSecond(_: Int) {
    fatalError("implements in subclass")
  }
}
