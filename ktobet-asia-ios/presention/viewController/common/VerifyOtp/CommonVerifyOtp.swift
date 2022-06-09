import Foundation

struct CommonVerifyOtpArgs {
    fileprivate(set) var title: String
    fileprivate(set) var description: String
    fileprivate(set) var identityTip: String
    fileprivate(set) var junkTip: String
    fileprivate(set) var otpExeedSendLimitError: String
    fileprivate(set) var isHiddenCSBarItem: Bool
    fileprivate(set) var isHiddenBarTitle: Bool
    fileprivate(set) var commonFailedType: CommonFailedTypeProtocol
}

protocol ICommonVerifyOtpBuilder {
    func build() -> CommonVerifyOtpArgs
}

class CommonVerifyOtpBuilder: ICommonVerifyOtpBuilder {
    private(set) var title: String = ""
    private(set) var description: String = ""
    private(set) var identityTip: String = ""
    private(set) var junkTip: String = ""
    private(set) var otpExeedSendLimitError: String = ""
    private(set) var isHiddenCSBarItem: Bool = true
    private(set) var isHiddenBarTitle: Bool = true
    private(set) var commonFailedType: CommonFailedTypeProtocol = CommonFailedType()
    
    fileprivate init(commonFailedType: CommonFailedTypeProtocol = CommonFailedType(),
                     title: String = "",
                     description: String = "",
                     identityTip: String = "",
                     junkTip: String = "",
                     otpExeedSendLimitError: String = "",
                     isHiddenCSBarItem: Bool = true,
                     isHiddenBarTitle: Bool = true) {
        self.title = title
        self.description = description
        self.identityTip = identityTip
        self.junkTip = junkTip
        self.otpExeedSendLimitError = otpExeedSendLimitError
        self.isHiddenCSBarItem = isHiddenCSBarItem
        self.isHiddenBarTitle = isHiddenBarTitle
        self.commonFailedType = commonFailedType
    }
    
    func build() -> CommonVerifyOtpArgs {
        CommonVerifyOtpArgs(title: title,
                            description: description,
                            identityTip: identityTip,
                            junkTip: junkTip,
                            otpExeedSendLimitError: otpExeedSendLimitError,
                            isHiddenCSBarItem: isHiddenCSBarItem,
                            isHiddenBarTitle: isHiddenBarTitle,
                            commonFailedType: commonFailedType)
    }
}

class CommonVerifyOtpFactory {
    enum VerifyType {
        case resetPassword
        case profileOld
        case profileNew
        case profileBrandNew
        case crypto
        case register
    }
    
    private var identity: String = ""
    
    static func create(identity: String, verifyType: VerifyType, accountType: AccountType, mode: ModifyMode = .oldModify) -> CommonVerifyOtpArgs {
        CommonVerifyOtpFactory().createVerifyOtp(identity: identity, verifyType: verifyType, accountType: accountType, mode: mode)
    }
    
    private func createVerifyOtp(identity: String, verifyType: VerifyType, accountType: AccountType, mode: ModifyMode = .oldModify) -> CommonVerifyOtpArgs {
        self.identity = identity
        switch verifyType {
        case .resetPassword:
            switch accountType {
            case .email:
                return resetPasswordEmailArgs()
            case .phone:
                return resetPasswordPhoneArgs()
            }
        case .profileOld:
            switch accountType {
            case .email:
                return profileOldEmailArgs()
            case .phone:
                return profileOldMobileArgs()
            }
        case .profileNew:
            switch accountType {
            case .email:
                return mode == .oldModify ? profileNewEmailArgs() : profileBrandNewEmailArgs()
            case .phone:
                return mode == .oldModify ? profileNewMobileArgs() : profileBrandNewMobileArgs()
            }
        case .crypto:
            switch accountType {
            case .email:
                return cryptoEmailArgs()
            case .phone:
                return cryptoPhoneArgs()
            }
        case .register:
            return registerPhoneArgs()
        case .profileBrandNew:
            switch accountType {
            case .phone:
                return profileBrandNewMobileArgs()
            case .email:
                return profileBrandNewEmailArgs()
            }
        }
    }

    private func profileOldEmailArgs() -> CommonVerifyOtpArgs {
        CommonVerifyOtpBuilder(commonFailedType: ProfileEmailFailedType(),
                               title: Localize.string("profile_identity_email_step2"),
                               description: Localize.string("profile_identity_email_step2_title"),
                               identityTip: Localize.string("common_otp_sent_content_email") + "\n" + identity,
                               junkTip: Localize.string("common_email_spam_check"),
                               otpExeedSendLimitError: Localize.string("common_email_otp_exeed_send_limit")).build()
    }
    
    private func profileOldMobileArgs() -> CommonVerifyOtpArgs {
        CommonVerifyOtpBuilder(commonFailedType: ProfileMobileFailedType(),
                               title: Localize.string("profile_identity_mobile_step2"),
                               description: Localize.string("profile_identity_mobile_step2_title"),
                               identityTip: Localize.string("common_otp_sent_content_mobile") + "\n" + identity,
                               otpExeedSendLimitError: Localize.string("common_sms_otp_exeed_send_limit")).build()
    }
    
    private func profileNewEmailArgs() -> CommonVerifyOtpArgs {
        CommonVerifyOtpBuilder(commonFailedType: ProfileEmailFailedType(),
                               title: Localize.string("profile_identity_email_step4"),
                               description: Localize.string("profile_identity_email_step4_title"),
                               identityTip: Localize.string("common_otp_sent_content_email") + "\n" + identity,
                               junkTip: Localize.string("common_email_spam_check"),
                               otpExeedSendLimitError: Localize.string("common_email_otp_exeed_send_limit")).build()
    }
    
    private func profileNewMobileArgs() -> CommonVerifyOtpArgs {
        CommonVerifyOtpBuilder(commonFailedType: ProfileMobileFailedType(),
                               title: Localize.string("profile_identity_mobile_step4"),
                               description: Localize.string("profile_identity_mobile_step4_title"),
                               identityTip: Localize.string("common_otp_sent_content_mobile") + "\n" + identity,
                               otpExeedSendLimitError: Localize.string("common_sms_otp_exeed_send_limit")).build()
    }
    
    private func profileBrandNewEmailArgs() -> CommonVerifyOtpArgs {
        CommonVerifyOtpBuilder(commonFailedType: ProfileEmailFailedType(),
                               description: Localize.string("profile_identity_email_step4_title"),
                               identityTip: Localize.string("common_otp_sent_content_email") + "\n" + identity,
                               junkTip: Localize.string("common_email_spam_check"),
                               otpExeedSendLimitError: Localize.string("common_email_otp_exeed_send_limit")).build()
    }
    
    private func profileBrandNewMobileArgs() -> CommonVerifyOtpArgs {
        CommonVerifyOtpBuilder(commonFailedType: ProfileMobileFailedType(),
                               description: Localize.string("profile_identity_mobile_step4_title"),
                               identityTip: Localize.string("common_otp_sent_content_mobile") + "\n" + identity,
                               otpExeedSendLimitError: Localize.string("common_sms_otp_exeed_send_limit")).build()
    }
    
    private func registerPhoneArgs() -> CommonVerifyOtpArgs {
        CommonVerifyOtpBuilder(commonFailedType: RegisterFailedType(),
                               title: Localize.string("register_step3_title_1"),
                               description: Localize.string("register_step3_verify_by_phone_title"),
                               identityTip: Localize.string("common_otp_sent_content_mobile") + "\n" + identity,
                               otpExeedSendLimitError: Localize.string("common_sms_otp_exeed_send_limit"),
                               isHiddenCSBarItem: false,
                               isHiddenBarTitle: false).build()
    }
    
    private func resetPasswordEmailArgs() -> CommonVerifyOtpArgs {
        CommonVerifyOtpBuilder(commonFailedType: ResetPasswrodFailedType(),
                               title: Localize.string("login_resetpassword_step2_title_1"),
                               description: Localize.string("login_resetpassword_step2_verify_by_email_title"),
                               identityTip: Localize.string("common_otp_sent_content_email") + "\n" + identity,
                               junkTip: Localize.string("common_email_spam_check"),
                               otpExeedSendLimitError: Localize.string("common_email_otp_exeed_send_limit"),
                               isHiddenCSBarItem: false,
                               isHiddenBarTitle: false).build()
    }

    private func resetPasswordPhoneArgs() -> CommonVerifyOtpArgs {
        CommonVerifyOtpBuilder(commonFailedType: ResetPasswrodFailedType(),
                               title: Localize.string("login_resetpassword_step2_title_1"),
                               description: Localize.string("login_resetpassword_step2_verify_by_phone_title"),
                               identityTip: Localize.string("common_otp_sent_content_mobile") + "\n" + identity,
                               otpExeedSendLimitError: Localize.string("common_sms_otp_exeed_send_limit"),
                               isHiddenCSBarItem: false,
                               isHiddenBarTitle: false).build()
    }
    
    private func cryptoEmailArgs() -> CommonVerifyOtpArgs {
        CommonVerifyOtpBuilder(commonFailedType: WithdrawalFailedType(),
                               description: Localize.string("common_verify_email"),
                               identityTip: Localize.string("common_otp_sent_content_email") + "\n" + identity,
                               junkTip: Localize.string("common_email_spam_check"),
                               otpExeedSendLimitError: Localize.string("common_email_otp_exeed_send_limit")).build()
    }
    
    private func cryptoPhoneArgs() -> CommonVerifyOtpArgs {
        CommonVerifyOtpBuilder(commonFailedType: WithdrawalFailedType(),
                               description: Localize.string("common_verify_mobile"),
                               identityTip: Localize.string("common_otp_sent_content_mobile") + "\n" + identity,
                               otpExeedSendLimitError: Localize.string("common_sms_otp_exeed_send_limit")).build()
    }
}
