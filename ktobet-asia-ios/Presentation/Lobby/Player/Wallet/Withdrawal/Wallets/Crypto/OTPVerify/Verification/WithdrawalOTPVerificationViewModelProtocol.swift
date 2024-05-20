import sharedbu

protocol WithdrawalOTPVerificationViewModelProtocol: AnyObject {
    var headerTitle: String { get }
    var sentCodeMessage: String { get }

    var otpCodeLength: Int { get }
    var timerText: String { get }

    var isLoading: Bool { get }

    var isResentOTPEnable: Bool { get }
    var isOTPVerifyInProgress: Bool { get }

    var isVerifiedFail: Bool { get }

    var otpCode: String { get set }

    func setup(accountType: sharedbu.AccountType)

    func verifyOTP(onCompleted: (() -> Void)?, onErrorRedirect: ((Error) -> Void)?)

    func resendOTP(onCompleted: (() -> Void)?, onErrorRedirect: ((Error) -> Void)?)
}
