import UIKit
import RxSwift
import SharedBu

class MaintenanceViewController: UIViewController {
    private var serviceViewModel = DI.resolve(ServiceStatusViewModel.self)!
    private var productType: ProductType!
    private var disposeBag = DisposeBag()
    private var timer: CountDownTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addMenuToBarButtonItem(vc: self)
        productType = ProductType.convert(self.view.tag)
        getMaintainRemainTime()
    }
    
    deinit {
        self.timer?.stop()
        print("\(type(of: self)) deinit")
    }
    
    private func getMaintainRemainTime() {
        Observable.just(productType).bind(to: serviceViewModel.input.playerDefaultProduct).disposed(by: disposeBag)
        serviceViewModel.output.maintainTime.drive(onNext: { [weak self] time in
            guard let `self` = self else { return }
            if time != nil {
                self.updateTimelabels(time!, Date())
            } else {
                NavigationManagement.sharedInstance.goTo(productType: self.productType)
            }
        }).disposed(by: disposeBag)
    }
    
    private func updateTimelabels(_ endTime: OffsetDateTime, _ now: Date) {
        let remainTime = TimeInterval(endTime.epochSeconds - now.convertDateToOffsetDateTime().epochSeconds)
        if self.timer == nil {
            self.timer = CountDownTimer()
        }
        self.timer?.start(timeInterval: 1, duration: remainTime) {[weak self] (index, countdownseconds, finish) in
            guard let `self` = self else { return }
            if finish {
                NavigationManagement.sharedInstance.goTo(productType: self.productType)
            } else {
                self.setTextPerSecond(countdownseconds)
            }
        }
    }
    
    public func setTextPerSecond(_ countdownseconds: Int) {
        fatalError("implements in subclass")
    }
}
