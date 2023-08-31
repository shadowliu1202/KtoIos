import RxSwift
import SharedBu
import UIKit

class MaintenanceViewController: LobbyViewController {
  @Injected private var maintenanceViewModel: MaintenanceViewModel
  @Injected private var serviceViewModel: ServiceStatusViewModel
  
  private var productType: ProductType!
  private var timer: CountDownTimer?
  
  var disposeBag = DisposeBag()

  override func viewDidLoad() {
    super.viewDidLoad()
    NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
    productType = ProductType.convert(self.view.tag)
    getMaintainRemainTime()
    bindProductStatus()
    
    // Change NavigationBar color when redirect from SearchViewController.
    Theme.shared.configNavigationBar(
      navigationController,
      backgroundColor: UIColor.greyScaleDefault.withAlphaComponent(0.9))
  }

  deinit {
    self.timer?.stop()
    Logger.shared.info("\(type(of: self)) deinit")
  }

  private func getMaintainRemainTime() {
    Observable.just(productType)
      .bind(to: serviceViewModel.input.playerDefaultProductType)
      .disposed(by: disposeBag)

    serviceViewModel.output.productMaintainTime.drive(onNext: { [weak self] time in
      guard let self else { return }
      if time != nil {
        self.updateTimelabels(time!)
      }
      else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          NavigationManagement.sharedInstance.goTo(productType: self.productType)
        }
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
  
  private func bindProductStatus() {
    maintenanceViewModel.productMaintenanceStatus
      .drive(onNext: { [weak self] productStatus in
        guard
          let self,
          !productStatus.isProductMaintain(productType: self.productType)
        else { return }
        
        let productNC = UIStoryboard(name: self.productType.name, bundle: nil)
          .instantiateViewController(withIdentifier: self.productType.name + "NavigationController") as! UINavigationController
        
        self.navigationController?.viewControllers = [productNC.topViewController!]
      })
      .disposed(by: disposeBag)
  }
}
