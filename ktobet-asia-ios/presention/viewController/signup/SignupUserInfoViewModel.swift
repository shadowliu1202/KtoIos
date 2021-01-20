//
//  RegisterViewModel.swift
//  KtoPra
//
//  Created by Partick Chen on 2020/10/21.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import share_bu

class SignupUserInfoViewModel {
    
    enum AccountType {
        case phone
        case email
    }
    
    enum UserInfoStatus{
        case valid
        case firstEmpty
        case empty
        case errNameFormat
        case errEmailFormat
        case errPhoneFormat
        case errPasswordFormat
        case errPasswordNotMatch
        case errEmailOtpInactive
        case errSMSOtpInactive
    }
    
    private var usecaseRegister : IRegisterUseCase!
    private var usecaseSystemStatus : GetSystemStatusUseCase!
    
    private var phoneEdited = false
    private var mailEdited = false
    private var passwordEdited = false
    private var nameEdited = false
    
    var relayName = BehaviorRelay(value: "")
    var relayEmail = BehaviorRelay(value: "")
    var relayMobile = BehaviorRelay(value: "")
    var relayPassword = BehaviorRelay(value: "")
    var relayConfirmPassword = BehaviorRelay(value: "")
    var relayAccountType = BehaviorRelay(value: AccountType.phone)
    var locale : SupportLocale = SupportLocale.China()
    
    init(_ usecaseRegister : IRegisterUseCase, _ usecaseSystem : GetSystemStatusUseCase) {
        self.usecaseRegister = usecaseRegister
        self.usecaseSystemStatus = usecaseSystem
    }
    
    func inputAccountType(_ type: AccountType){
        relayAccountType.accept(type)
    }
    
    func inputLocale(_ locale: SupportLocale){
        self.locale = locale
    }
    
    func currentAccountType()->AccountType{
        return relayAccountType.value
    }
    
    func currentPassword()->String{
        return relayPassword.value
    }
    
    func event()->(otpValid : Observable<UserInfoStatus>,
                   emailValid : Observable<UserInfoStatus>,
                   mobileValid : Observable<UserInfoStatus>,
                   nameValid : Observable<UserInfoStatus>,
                   passwordValid : Observable<UserInfoStatus>,
                   dataValid : Observable<Bool>,
                   typeChange : Observable<AccountType>){
        
        let nameValid = relayName
            .map { (text) -> UserInfoStatus in
                let valid = self.locale.verifyWithdrawalNameFormat(name: text)
                if text.count > 0 { self.nameEdited = true }
                if valid { return .valid }
                else if text.count == 0{
                    if self.nameEdited { return .empty}
                    else { return .firstEmpty }
                } else {
                    return .errNameFormat
                }
            }
        
        let emailValid = relayEmail
            .map { (text) -> UserInfoStatus in
                let valid = Account.Email(email: text).isValid()
                if text.count > 0 { self.mailEdited = true }
                if valid { return .valid}
                else if text.count == 0 {
                    if self.mailEdited{ return .empty }
                    else { return .firstEmpty }
                }
                else { return .errEmailFormat}
            }
        
        let mobileValid = relayMobile
            .map { (text) -> UserInfoStatus in
                let valid = Account.Phone(phone: text, locale: self.locale).isValid()
                if text.count > 0 { self.phoneEdited = true }
                if valid { return .valid}
                else if text.count == 0 {
                    if self.phoneEdited { return .empty }
                    else { return .firstEmpty }
                }
                else { return .errPhoneFormat}
            }
        
        let password = relayPassword.asObservable()
        let confirmPassword = relayConfirmPassword.asObservable()
        let passwordValid = password
            .flatMapLatest { (passwordText)  in
                return confirmPassword.map { (confirmPasswordText) -> UserInfoStatus in
                    let valid = UserPassword.Companion().verify(password: passwordText)
                    if passwordText.count > 0 { self.passwordEdited = true }
                    if passwordText.count == 0{
                        if self.passwordEdited { return .empty }
                        else { return .firstEmpty }
                    } else if (!valid){
                        return .errPasswordFormat
                    } else if passwordText != confirmPasswordText{
                        return .errPasswordNotMatch
                    } else {
                        return .valid
                    }
                }
            }
        
        let typeChange = relayAccountType.asObservable()
        
        let accountValid = Observable.combineLatest(typeChange, emailValid, mobileValid){
            ($0 == AccountType.email && $1 == UserInfoStatus.valid) ||
            ($0 == AccountType.phone && $2 == UserInfoStatus.valid)
        }
    
        let dataValid = Observable
            .combineLatest(nameValid, accountValid, passwordValid){
                (($0 == UserInfoStatus.valid) && $1 && ($2 == UserInfoStatus.valid))
            }
        
        let otpValid = usecaseSystemStatus
            .getOtpStatus()
            .asObservable()
            .concatMap { otpStatus  in
                return typeChange.map { (type)  -> UserInfoStatus in
                    switch type{
                    case .email: return otpStatus.isMailActive ? .valid : .errEmailOtpInactive
                    case .phone: return otpStatus.isSmsActive ? .valid : .errSMSOtpInactive
                    }
                }
            }
        
        return (otpValid : otpValid,
                emailValid : emailValid,
                mobileValid : mobileValid,
                nameValid : nameValid,
                passwordValid : passwordValid,
                dataValid : dataValid,
                typeChange : typeChange)
    }
    

    func register()->Single<(type: AccountType, account: String, password: String)>  {
        let userAccount : UserAccount = {
            switch relayAccountType.value{
            case .phone:
                return UserAccount(username: relayName.value, type: Account.Phone(phone: relayMobile.value, locale: locale))
            case .email:
                return UserAccount(username: relayName.value, type: Account.Email(email: relayEmail.value))
            }
        }()
        let userPassword = UserPassword(value: relayPassword.value)
        let nextAction =  Single<(type: AccountType, account: String, password: String)>
            .create { (single) -> Disposable in
                var account = ""
                let password = self.relayPassword.value
                switch self.relayAccountType.value{
                case .phone: account = self.relayMobile.value
                case .email: account = self.relayEmail.value
                }
                single(.success((self.relayAccountType.value, account, password)))
                return Disposables.create {}
            }
        return usecaseRegister
            .register(account: userAccount, password: userPassword, locale: self.locale)
            .andThen(nextAction)
    }
}
