import Combine
import RxCocoa
import RxSwift
import sharedbu
import SwiftUI

class PortalMaintenanceViewModel: ComposeObservableObject<PortalMaintenanceViewModel.Event> {
    enum Event {}

    @Injected var systemStatusUseCase: ISystemStatusUseCase

    private var disposeBag = DisposeBag()
    private var perSecondsRefreshTimer: Observable<Int> = .interval(.seconds(1), scheduler: MainScheduler.instance)

    @Published var supportEmail: String = ""
    @Published var timerHours: String = "00"
    @Published var timerMinutes: String = "00"
    @Published var timerSeconds: String = "00"
    @Published var isMaintenanceOver: Bool = false
    @Published var remainSeconds: Int? = nil

    override init() {
        super.init()

        systemStatusUseCase.fetchCustomerServiceEmail().subscribe { email in
            self.supportEmail = email
        }.disposed(by: disposeBag)

        perSecondsRefreshTimer
            .subscribe(onNext: { _ in
                self.systemStatusUseCase.refreshMaintenanceState()
            }).disposed(by: disposeBag)

        systemStatusUseCase.observeMaintenanceStatusByFetch()
            .do { status in
                switch onEnum(of: status) {
                case let .allPortal(microseconds):

                    guard let newRemainSeconds = microseconds.convertDurationToSeconds()?.int32Value else {
                        self.remainSeconds = 0
                        return
                    }

                    if let remainSeconds = self.remainSeconds {
                        if abs(Int(newRemainSeconds) - remainSeconds) > 60 {
                            self.remainSeconds = Int(newRemainSeconds)
                        }
                    } else { 
                        self.remainSeconds = Int(newRemainSeconds)
                    }

                case .product:
                    self.remainSeconds = 0
                }
            }
            .subscribe()
            .disposed(by: disposeBag)
    }

    func openEmailURL() {
        let email = supportEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, let url = URL(string: "mailto:\(email)") else { return }
        UIApplication.shared.open(url)
    }
}
