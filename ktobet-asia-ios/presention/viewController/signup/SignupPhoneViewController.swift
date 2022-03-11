//
//  Register3ViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/29.
//

import UIKit
import RxSwift
import RxCocoa
import SharedBu

class SignupPhoneViewController: OtpViewControllerProtocol {
    private var viewModel = DI.resolve(SignupPhoneViewModel.self)!
    private var disposeBag = DisposeBag()
    
    var commonVerifyOtpArgs: CommonVerifyOtpArgs
    
    init(phoneNumber: String, countryCode: String) {
        self.commonVerifyOtpArgs = CommonVerifyOtpFactory.create(identity: [countryCode, phoneNumber].joined(separator: " "), verifyType: .register, accountType: .phone)
    }
    
    func verify(otp: String) -> Completable {
        viewModel.otpVerify(otp: otp).asCompletable().do(onCompleted: {[weak self] in self?.onVerified() })
    }
    
    func resendOtp() -> Completable {
        viewModel.resendRegisterOtp()
    }
    
    func onCloseVerifyProcess() {
        Alert.show(Localize.string("common_tip_title_unfinished"), Localize.string("common_tip_content_unfinished")) {
            UIApplication.topViewController()?.navigationController?.popToRootViewController(animated: true)
        } cancel: { }
    }
    
    func validateAccountType(validator: OtpValidator) {
        let type = EnumMapper.convert(accountType: AccountType.phone.rawValue)
        validator.otpAccountType.onNext(type)
    }
    
    func onExccedResendLimit() {
        Alert.show(Localize.string("common_tip_title_warm"), Localize.string("common_sms_otp_exeed_send_limit"), confirm: {
            UIApplication.topViewController()?.navigationController?.popToRootViewController(animated: true)
        }, cancel: nil)
    }
    
    private func onVerified() {
        NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "DefaultProductNavigationViewController")
    }
}
