import Foundation
import RxSwift
import RxCocoa
import SharedBu

class NewPasswordValidator {
    private(set) var passwordEdited: Bool = false
    private(set) var accountPassword: BehaviorRelay<String>
    private(set) var confirmPassword: BehaviorRelay<String>
    
    lazy var passwordValidationError: Observable<UserInfoStatus> = self.accountPassword.flatMapLatest({ [unowned self] (passwordText) in
        return self.confirmPassword.asObservable().map({ [unowned self] (confirmPasswordText) -> UserInfoStatus in
            return self.verifyPassword(passwordText: passwordText, confirmPasswordText: confirmPasswordText)
        })
    })
    lazy var isPasswordValid: Observable<Bool> = self.passwordValidationError.map({ $0 == .valid })
    
    init(accountPassword: BehaviorRelay<String>, confirmPassword: BehaviorRelay<String>) {
        self.accountPassword = accountPassword
        self.confirmPassword = confirmPassword
    }
    
    private func verifyPassword(passwordText: String, confirmPasswordText: String) -> UserInfoStatus {
        let valid = UserPassword.Companion().verify(password: passwordText)
        if passwordText.count > 0 { self.passwordEdited = true }
        if passwordText.count == 0 {
            if self.passwordEdited { return .empty }
            else { return .firstEmpty }
        } else if (!valid){
            return .errPasswordFormat
        } else if passwordText != confirmPasswordText {
            return .errPasswordNotMatch
        } else {
            return .valid
        }
    }
}
