import Combine
import RxSwift
import sharedbu

class OtpVerification: ComposeObservableObject<OtpVerification.Event> {
    enum Event {
        case verified, exceedResendLimit(AccountType), fatalError, resendSuccess, wrongOtp
    }

    struct State {
        var otp: String = ""
        var supportLocale: SupportLocale = .Vietnam()
        var selectMethod: AccountType = .phone
        var accountType: sharedbu.AccountType {
            switch selectMethod {
            case .phone:
                sharedbu.AccountType.phone
            case .email:
                sharedbu.AccountType.email
            }
        }

        var otpPattern: sharedbu.OtpPattern {
            AccountPatternGeneratorFactory.create(supportLocale).otp(type: accountType)
        }

        var otpLength: Int {
            Int(otpPattern.validLength())
        }

        var isOtpValid: Bool {
            otpPattern.verify(digit: otp)
        }
    }

    @Injected private var playerConfiguration: PlayerConfiguration
    @Injected private var resetUseCase: ResetPasswordUseCase
    @Published var otpCode: String = ""
    @Published var state: State = .init()
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    init(accountType: AccountType) {
        super.init()
        state = State(supportLocale: playerConfiguration.supportLocale, selectMethod: accountType)
        $otpCode.eraseToAnyPublisher()
            .sink { [unowned self] in state.otp = $0 }
            .store(in: &cancellables)
    }

    func verifyResetOtp(otpCode: String) {
        resetUseCase.verifyResetOtp(otp: otpCode)
            .subscribe(onCompleted: { [unowned self] in
                publisher = .event(.verified)
            }, onError: { [unowned self] error in
                handleErrors(error)
            })
            .disposed(by: disposeBag)
    }

    func resendOtp() {
        resetUseCase.resendOtp()
            .subscribe(onCompleted: { [unowned self] in
                publisher = .event(.resendSuccess)
            }, onError: { [unowned self] error in
                handleErrors(error)
            })
            .disposed(by: disposeBag)
    }

    func handleErrors(_ error: Error) {
        switch error {
        case is PlayerOtpCheckError:
            publisher = .event(.wrongOtp)
        case is PlayerOverOtpRetryLimit:
            publisher = .event(.fatalError)
        case is PlayerIpOverOtpDailyLimit:
            publisher = .event(.exceedResendLimit(state.selectMethod))
        case is ApiException:
            publisher = .event(.fatalError)
        default:
            publisher = .error(error)
        }
    }
}
