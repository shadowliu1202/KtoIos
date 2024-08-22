import Combine
import RxCocoa
import RxSwift
import sharedbu
import SwiftUI

class PortalMaintenanceViewModel: ComposeObservableObject<PortalMaintenanceViewModel.Event> {
    @Injected var systemStatusUseCase: ISystemStatusUseCase

    @Published var supportEmail: String = "support@example.com"
    @Published var timerHours: String = "00"
    @Published var timerMinutes: String = "00"
    @Published var timerSeconds: String = "00"
    @Published var isMaintenanceOver: Bool = false

    enum Event {}

    private var disposeBag = DisposeBag()

    override init() {
        super.init()

        systemStatusUseCase.fetchCustomerServiceEmail().subscribe { email in
            self.supportEmail = email
        }.disposed(by: disposeBag)

        systemStatusUseCase.fetchMaintenanceStatus()
            .asObservable()
            .flatMap { status -> Observable<Int> in
                switch onEnum(of: status) {
                case let .allPortal(microseconds):
                    guard let initialSeconds = microseconds.convertDurationToSeconds()?.int32Value else {
                        return Observable<Int>.once(0)
                    }
                    return Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
                        .map { interval in
                            Int(initialSeconds) - Int(interval)
                        }
                case .product:
                    return Observable.once(0)
                }
            }
            .subscribe(onNext: { secondsRemaining in
                if secondsRemaining == 0 {
                    self.isMaintenanceOver = true
                    self.disposeBag = DisposeBag()
                } else {
                    self.updateRemainingTime(secondsRemaining)

                    self.systemStatusUseCase.fetchMaintenanceStatus()
                        .subscribe { status in
                            switch onEnum(of: status) {
                            case let .allPortal(it):
                                if let newSeconds = it.convertDurationToSeconds()?.int32Value,
                                   newSeconds <= secondsRemaining
                                {
                                    self.updateRemainingTime(Int(newSeconds))
                                }
                            case .product:
                                self.isMaintenanceOver = true
                                self.disposeBag = DisposeBag()
                            }
                        }
                        .disposed(by: self.disposeBag)
                }
            })
            .disposed(by: disposeBag)
    }

    private func updateRemainingTime(_ countDownSecond: Int) {
        timerHours = String(format: "%02d", countDownSecond / 3600)
        timerMinutes = String(format: "%02d", (countDownSecond / 60) % 60)
        timerSeconds = String(format: "%02d", countDownSecond % 60)
    }

    private func navigateToLogin() {
        NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
    }

    func openEmailURL() {
        let email = supportEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, let url = URL(string: "mailto:\(email)") else { return }
        UIApplication.shared.open(url)
    }
}
