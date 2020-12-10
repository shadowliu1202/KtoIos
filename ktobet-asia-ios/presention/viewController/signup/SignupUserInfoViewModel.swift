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
    
    private var registerUseCase : IRegisterUseCase!
    
    var account = BehaviorRelay(value: "15559966049")
    var password = BehaviorRelay(value: "111111")
    var name = BehaviorRelay(value: "qqq")
    var type = BehaviorSubject<AccountType>(value: .phone)
    var locale : SupportLocale = SupportLocale.China()
    
    init(_ registerUseCase : IRegisterUseCase) {
        self.registerUseCase = registerUseCase
    }
    
    func output()->(nameValid : Observable<Bool>,
                    accountValid : Observable<(valid: Bool, type: AccountType)>,
                    passwordValid : Observable<Bool>,
                    dataValid : Observable<Bool>,
                    typeChange : BehaviorSubject<AccountType>){
        
        let nameValid = name.map { (text) -> Bool in
            let valid = self.locale.verifyWithdrawalNameFormat(name: text)
            return valid
        }
        
        let accountValid = account.map { (text) -> (valid: Bool, type: AccountType) in
            var valid = false
            let type = (try? self.type.value()) ?? .phone
            switch type{
            case .email: valid = Account.Email(email: text).isValid()
            case .phone: valid = Account.Phone(phone: text, locale: self.locale).isValid()
            }
            return (valid, type)
        }

        let passwordValid = password.map { (text) -> Bool in
            let valid = UserPassword.Companion().verify(password: text)
            return valid
        }
        
        let dataValid = Observable.combineLatest(nameValid, accountValid, passwordValid){
            $0 && $1.valid && $2
        }
        
        return (nameValid, accountValid, passwordValid, dataValid, type)
    }
    
    func typeChange(_ type : AccountType){
        self.type.onNext(type)
    }
    
    func register()->(completable : Completable, type : AccountType)  {
        let tp = (try? self.type.value()) ?? .phone
        let userAccount : UserAccount = {
            switch tp{
            case .phone: return UserAccount(username: self.name.value, type: Account.Phone(phone: account.value, locale: self.locale))
            case .email: return UserAccount(username: self.name.value, type: Account.Email(email: account.value))
            }
        }()
        let userPassword = UserPassword(value: password.value)
        return (registerUseCase.register(account: userAccount, password: userPassword, locale: self.locale), tp)
    }
}
