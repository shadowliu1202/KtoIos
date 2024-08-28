import Combine
import RxCocoa
import RxSwift
import sharedbu
import SwiftUI

class PortalMaintenance: ComposeObservableObject<PortalMaintenance.Event> {
    enum Event {
        case isMaintenanceOver
    }

    @Injected var systemStatusUseCase: ISystemStatusUseCase

    private var disposeBag = DisposeBag()
    private static var networkDelayGap = 10

    @Published var supportEmail: String = ""
    @Published var remainSeconds: Int? = nil

    override init() {
        super.init()
        systemStatusUseCase.fetchCustomerServiceEmail().subscribe { email in
            self.supportEmail = email
        }.disposed(by: disposeBag)

        Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.systemStatusUseCase.refreshMaintenanceState()
            }).disposed(by: disposeBag)

        systemStatusUseCase.observeMaintenanceStatusByFetch()
            .subscribe(onNext: { status in
                switch onEnum(of: status) {
                case let .allPortal(microseconds):
                    guard let newRemainSeconds = microseconds.convertDurationToSeconds()?.int32Value else { return }

                    if let remainSeconds = self.remainSeconds {
                        if abs(Int(newRemainSeconds) - remainSeconds) > PortalMaintenance.networkDelayGap {
                            self.remainSeconds = Int(newRemainSeconds)
                        }
                    } else {
                        self.remainSeconds = Int(newRemainSeconds)
                    }

                case .product:
                    self.remainSeconds = 0
                    self.publisher = .event(.isMaintenanceOver)
                }
            })
            .disposed(by: disposeBag)
    }
}
