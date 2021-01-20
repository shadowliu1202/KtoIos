//
//  ErrorType.swift
//  ktobet-asia-ios
//
//  Created by Patrick.chen on 2021/1/14.
//

import Foundation
import share_bu


enum ErrorType : Int {
    case PlayerIsExist = 10002
    case PlayerIsNotExist = 10001
    case PlayerLoginFail = 10003
    case PlayerEditFail = 10004
    case PlayerRegisterFail = 10005
    case PlayerAddTempPlayerFail = 10006
    case PlayerGetTempPlayerFail = 10007
    case PlayerResentOtpOverTenTimes = 10008
    case PlayerAddInfoFail = 10009
    case PlayerChangePasswordFail = 10010
    case PlayerPasswordFail = 10011
    case PlayerAddCaptchaFail = 10012
    case PlayerCaptchaCheckError = 10013
    case PlayerDuplicatedLogin = 10014
    case PlayerAddForgetPasswordTempDataFail = 10015
    case PlayerGetForgetPasswordTempDataFail = 10016
    case PlayerPasswordRepeat = 10017
    case PlayerCaptchaNotFound = 10019
    case PlayerIsLocked = 10020
    case PlayerIsSuspend = 10021
    case PlayerIsInactive = 10022
    case PlayerApplyResetPasswordRepeat = 10023
    case PlayerResentOtpLessResendTime = 10024
    case PlayerAddWithdrawalCacheFail = 10025
    case PlayerOverOtpRetryLimit = 10026
    case PlayerIpOverOtpDailyLimit = 10027
    case PlayerIdOverOtpLimit = 10028
    case PlayerForgetPasswordTempDataExist = 10029
    case PlayerLoginIdIsExist = 10030
    case PlayerIsNotLogged = 10031
    case PlayerAffiliateApplyStatusIsApplying = 10032
    case PlayerAffiliateApplyStatusIsAppliedButInActive = 10033
    case PlayerAffiliateApplyStatusIsAppliedButSuspend = 10034
    case PlayerDepositCountOverLimit = 10101
    case PlayerPaymentTokenInactive = 10102
    case PlayerPaymentTokenNotInPlayerPaymentGroup = 10103
    case PlayerWithdrawalDefective = 10104
    case PlayerOtpCheckError = 10200
    case PlayerOtpInsertRedisError = 10201
    case PlayerSendOtpTargetAddressError = 10202
    case PlayerSendOtpTypeError = 10203
    case PlayerUrlOtpInsertRedisError = 10204
    case PlayerOtpCheckErrorByChangePassword = 10205
    case PlayerSendOtpFail = 10206
    case PlayerOtpMailInactive = 10207
    case PlayerOtpSmsInactive = 10208
    case PlayerReSendOtpError = 10209
    case PlayerCommentIsNotExist = 10300
    case PlayerChatTokenError = 10400
    case PlayerChatNotAllow = 10401
    case PlayerProfileUpdateError = 10500
    case PlayerProfileAddError = 10501
    case PlayerProfileBindError = 10502
    case PlayerProfileAlreadyExist = 10503
    case PlayerProfileInvalidInput = 10504
    case PlayerProfileRealNameChangeForbidden = 10505
    case BonusReachTheApplicantLimitation = 10701
    case BonusBalanceLowerMinimumLimit = 10702
    case BonusCouponIsLocked = 10703
    case BonusCouponDepositAmountOrTimesNotEnough = 10704
    case BonusCouponIsUsing = 10705
    case BonusCouponIsNotExist = 10706
    case BonusPlayerTurnoverIsNotExists = 10707
    case BonusElkNoResult = 10708
    case BonusCouponIsUsed = 10709
    case PlayerRegisterError = 10801
    case PlayerForgetPasswordError = 10802
    case DBPlayerNotExist = 50000
    case DBPlayerAlreadyExist = 50001
    case DBPlayerUpdateError = 50002
    case DBPlayerWithdrawalRequestInsufficientBalance = 50101
    case ApiUnknownException
}


class LoginError : NSError{
    var status : LoginStatus.TryStatus?
    var isLock : Bool?
}
