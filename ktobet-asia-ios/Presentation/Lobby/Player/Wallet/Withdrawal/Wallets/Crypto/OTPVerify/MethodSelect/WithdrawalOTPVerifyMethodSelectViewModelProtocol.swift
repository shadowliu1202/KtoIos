import Foundation
import sharedbu

protocol WithdrawalOTPVerifyMethodSelectViewModelProtocol: AnyObject {
    var otpServiceAvailability: WithdrawalOTPVerifyMethodSelectDataModel.OTPServiceStatus { get }
    var isLoading: Bool { get }
    var isOTPRequestInProgress: Bool { get }

    var selectedAccountType: sharedbu.AccountType { get set }

    func setup(_ otpServiceUnavailable: (() -> Void)?)

    func requestOTP(
        bankCardID: String,
        onCompleted: ((_ selectedAccountType: sharedbu.AccountType) -> Void)?)
}

struct WithdrawalOTPVerifyMethodSelectDataModel {
    enum OTPServiceStatus: Equatable {
        case available(_ infoHint: String, _ isRequestAvailable: Bool)
        case unavailable(_ hint: String)
    }
}
