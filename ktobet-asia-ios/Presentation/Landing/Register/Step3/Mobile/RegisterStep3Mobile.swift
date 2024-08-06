import Combine
import RxSwift
import sharedbu

class RegisterStep3Mobile: ComposeObservableObject<RegisterStep3Mobile.Event> {
    enum Event {
        case verified(ProductType?), exceedResendLimit, fatalError, resendSuccess
    }

    struct State {
        var errorMessage: String? = nil
        var otp: String = ""
        var supportLocale: SupportLocale = .Vietnam()
        var otpPattern: OtpPattern { AccountPatternGeneratorFactory.create(supportLocale).otp(type: .phone) }
        var otpLength: Int { Int(otpPattern.validLength()) }
        var isOtpValid: Bool { otpPattern.verify(digit: otp) }
        var isProcessing: Bool = false
    }

    @Injected private var playerConfiguration: PlayerConfiguration
    @Injected private var registerUseCase: RegisterUseCase
    @Published var otpCode: String = ""
    @Published var state: State = .init()
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        state = .init(supportLocale: playerConfiguration.supportLocale)
        $otpCode.eraseToAnyPublisher()
            .sink { [unowned self] in
                state.otp = $0
                state.errorMessage = nil
            }
            .store(in: &cancellables)
    }

    func verifyOtp(otpCode: String) {
        state.isProcessing = true
        registerUseCase.loginFrom(otp: otpCode)
            .subscribe(
                onSuccess: { [unowned self] player in
                    publisher = .event(.verified(player.defaultProduct))
                },
                onFailure: { [unowned self] error in
                    state.isProcessing = false
                    handleErrors(error)
                }
            )
            .disposed(by: disposeBag)
    }

    func resendOtp() {
        registerUseCase.resendRegisterOtp()
            .subscribe(
                onCompleted: { [unowned self] in publisher = .event(.resendSuccess) },
                onError: { [unowned self] error in handleErrors(error) }
            )
            .disposed(by: disposeBag)
    }

    func handleErrors(_ error: Error) {
        switch error {
        case is PlayerOtpCheckError:
            state.errorMessage = Localize.string("register_step3_incorrect_otp")
        case is PlayerOverOtpRetryLimit:
            publisher = .event(.fatalError)
        case is PlayerIpOverOtpDailyLimit:
            publisher = .event(.exceedResendLimit)
        case is ApiException:
            publisher = .event(.fatalError)
        default:
            publisher = .error(error)
        }
    }
}
