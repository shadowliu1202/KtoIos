import Foundation
import RxSwift
import sharedbu

class ResetPassword: ComposeObservableObject<ResetPassword.Event> {
    enum Event {
        case resetSuccess, navToError
    }

    struct State {
        enum PasswordVerification {
            case errorFormat, notMatch, isEmpty, valid
        }

        var password: String? = nil
        var confirmPassword: String? = nil
        var verification: PasswordVerification? {
            guard let password, let confirmPassword else { return nil }
            if password.isEmpty || confirmPassword.isEmpty {
                return .isEmpty
            } else if !UserPassword.Companion().verify(password: password) {
                return .errorFormat
            } else if password != confirmPassword {
                return .notMatch
            } else {
                return .valid
            }
        }
    }

    @Injected private var playerConfiguration: PlayerConfiguration
    @Injected private var resetUseCase: ResetPasswordUseCase
    @Published var state: State = .init()
    private let disposeBag = DisposeBag()

    func reset(password: String) {
        resetUseCase.resetPassword(password: password)
            .subscribe(onCompleted: { [unowned self] in
                publisher = .event(.resetSuccess)
            }, onError: { [unowned self] error in
                switch error {
                case is PlayerChangePasswordFail:
                    publisher = .event(.navToError)
                default:
                    publisher = .error(error)
                }
            })
            .disposed(by: disposeBag)
    }
}
