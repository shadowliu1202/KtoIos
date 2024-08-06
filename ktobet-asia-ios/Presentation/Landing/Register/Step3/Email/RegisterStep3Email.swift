import Combine
import Foundation
import RxSwift
import sharedbu
import SwiftUI

class RegisterStep3Email: ComposeObservableObject<RegisterStep3Email.Event> {
    private static let AutoVerifyInterval: TimeInterval = 5
    enum Event {
        case verified(ProductType?),
             invalid,
             resendSuccess,
             exceedLimit
    }

    @Injected private var registerUseCase: RegisterUseCase
    @Injected private var authenticationUseCase: AuthenticationUseCase

    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    @Published var isAutoVerify: Bool = true

    init(_ identity: String, _ password: String) {
        super.init()
        Observable<Int>.interval(.seconds(5), scheduler: MainScheduler.instance)
            .flatMapLatest { [unowned self] _ -> Observable<Event> in
                if isAutoVerify { verifyAndLogin(identity, password).asObservable() } else { .never() }
            }
            .subscribe(
                onNext: { [unowned self] data in if case Event.verified = data { publisher = .event(data) } },
                onError: { _ in }
            )
            .disposed(by: disposeBag)
    }

    func manualVerify(_ identity: String, _ password: String) {
        verifyAndLogin(identity, password)
            .subscribe(
                onSuccess: { [unowned self] result in publisher = .event(result) },
                onFailure: { [unowned self] error in handleErrors(error) }
            )
            .disposed(by: disposeBag)
    }

    private func verifyAndLogin(_ identity: String, _ password: String) -> Single<Event> {
        registerUseCase.checkAccountVerification(identity)
            .flatMap { [unowned self] result in
                if result {
                    authenticationUseCase.login(account: identity, pwd: password, captcha: Captcha(passCode: ""))
                        .map { player -> Event in .verified(player.defaultProduct) }
                } else {
                    Single.just(.invalid)
                }
            }
    }

    func resend() {
        registerUseCase.resendRegisterOtp()
            .subscribe(onCompleted: { [unowned self] in
                publisher = .event(.resendSuccess)
            }, onError: { [unowned self] error in
                handleErrors(error)
            })
            .disposed(by: disposeBag)
    }

    private func handleErrors(_ error: Error) {
        switch error {
        case is PlayerIdOverOtpLimit,
             is PlayerIpOverOtpDailyLimit,
             is PlayerOverOtpRetryLimit,
             is PlayerResentOtpOverTenTimes:
            publisher = .event(.exceedLimit)
        default:
            publisher = .error(error)
        }
    }
}
