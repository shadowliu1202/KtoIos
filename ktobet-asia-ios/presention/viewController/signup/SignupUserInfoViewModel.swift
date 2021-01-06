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
    
    private var relayName = BehaviorRelay(value: "")
    private var relayAccunt = BehaviorRelay(value: "")
    private var relayPassword = BehaviorRelay(value: "")
    private var relayConfirmPassword = BehaviorRelay(value: "")
    private var relayAccountType = BehaviorRelay(value: AccountType.phone)
    
    var locale : SupportLocale = SupportLocale.China()
    
    init(_ usecaseRegister : IRegisterUseCase, _ usecaseSystem : GetSystemStatusUseCase) {
        self.usecaseRegister = usecaseRegister
        self.usecaseSystemStatus = usecaseSystem
    }
    
    func inputName(_ name : String){
        relayName.accept(name)
    }
    
    func inputAccount(_ account : String){
        relayAccunt.accept(account)
    }
    
    func inputPassword(_ password: String){
        relayPassword.accept(password)
    }
    
    func inputConfirmPassword(_ confirmPassword : String){
        relayConfirmPassword.accept(confirmPassword)
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
    
    func currentAccount()->String{
        return relayAccunt.value
    }
    
    func currentPassword()->String{
        return relayPassword.value
    }
    
    func event()->(otpValid : Observable<UserInfoStatus>,
                   nameValid : Observable<UserInfoStatus>,
                   accountValid : Observable<UserInfoStatus>,
                   passwordValid : Observable<UserInfoStatus>,
                   dataValid : Observable<Bool>,
                   typeChange : Observable<AccountType>){
        
        let nameValid = relayName
            .map { (text) -> UserInfoStatus in
                let valid = self.locale.verifyWithdrawalNameFormat(name: text)
                if valid { return .valid }
                else if text.count == 0 { return .empty}
                else { return .errNameFormat}
            }
        
        let accountValid = relayAccunt
            .map { (text) -> UserInfoStatus in
                let type = self.relayAccountType.value
                let valid : Bool = {
                    switch type {
                    case .email: return Account.Email(email: text).isValid()
                    case .phone: return Account.Phone(phone: text, locale: self.locale).isValid()
                    }
                }()
                if valid { return .valid }
                else if text.count == 0 { return .empty }
                else {
                    switch type{
                    case .email: return .errEmailFormat
                    case .phone: return .errPhoneFormat
                    }
                }
            }

        
        let password = relayPassword.asObservable()
        let confirmPassword = relayConfirmPassword.asObservable()
        let passwordValid = password
            .flatMapLatest { (passwordText)  in
                return confirmPassword.map { (confirmPasswordText) -> UserInfoStatus in
                    let valid = UserPassword.Companion().verify(password: passwordText)
                    if passwordText.count == 0{
                        return .empty
                    } else if (!valid){
                        return .errPasswordFormat
                    } else if passwordText != confirmPasswordText{
                        return .errPasswordNotMatch
                    } else {
                        return .valid
                    }
                }
            }
        
        let dataValid = Observable
            .combineLatest(nameValid, accountValid, passwordValid){
                (($0 == UserInfoStatus.valid) && ($1 == UserInfoStatus.valid) && ($2 == UserInfoStatus.valid))
            }
        
        let typeChange = relayAccountType.asObservable()
        
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
                nameValid : nameValid,
                accountValid : accountValid,
                passwordValid : passwordValid,
                dataValid : dataValid,
                typeChange : typeChange)
    }
    

    func register()->Completable  {
        let userAccount : UserAccount = {
            switch relayAccountType.value{
            case .phone: return UserAccount(username: relayName.value, type: Account.Phone(phone: relayAccunt.value, locale: locale))
            case .email: return UserAccount(username: relayName.value, type: Account.Email(email: relayAccunt.value))
            }
        }()
        let userPassword = UserPassword(value: relayPassword.value)
        return usecaseRegister.register(account: userAccount, password: userPassword, locale: self.locale)
    }
}
