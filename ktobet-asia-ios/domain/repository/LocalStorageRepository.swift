//
//  LocalStorageRepository.swift
//  ktobet-asia-ios
//
//  Created by Patrick.chen on 2021/1/21.
//

import Foundation

class LocalStorageRepository{
    
    let kRememberAccount = "rememberAccount"
    let kLastOverLoginLimitDate = "overLoginLimit"
    let kNeedCaptcha = "needCaptcha"
    let kRememberMe = "rememberMe"
    
    func getRememberMe()-> Bool{
        return UserDefaults.standard.bool(forKey: kRememberMe)
    }
    
    func getRemeberAccount()->String{
        return UserDefaults.standard.string(forKey: kRememberAccount) ?? ""
    }
    
    func getLastOverLoginLimitDate()->Date{
        guard let date = UserDefaults.standard.object(forKey: kLastOverLoginLimitDate) as? Date else{
            return Date()
        }
        return date
    }
    
    func getNeedCaptcha()->Bool{
        return UserDefaults.standard.bool(forKey: kNeedCaptcha)
    }
    
    func setRememberMe(_ rememberMe : Bool?){
        if rememberMe == nil { UserDefaults.standard.removeObject(forKey: kRememberMe) }
        else { UserDefaults.standard.setValue(rememberMe, forKey: kRememberMe) }
        UserDefaults.standard.synchronize()
    }
    
    func setRemeberAccount(_ rememberAccount : String?){
        if rememberAccount == nil{ UserDefaults.standard.removeObject(forKey: kRememberAccount)}
        else { UserDefaults.standard.setValue(rememberAccount, forKey: kRememberAccount)}
        UserDefaults.standard.synchronize()
    }
    
    func setLastOverLoginLimitDate(_ lastOverLoginLimitDate : Date?){
        if lastOverLoginLimitDate == nil { UserDefaults.standard.removeObject(forKey: kLastOverLoginLimitDate)}
        else { UserDefaults.standard.setValue(lastOverLoginLimitDate, forKey: kLastOverLoginLimitDate)}
        UserDefaults.standard.synchronize()
    }
    
    func setNeedCaptcha(_ needCaptcha : Bool?){
        if needCaptcha == nil { UserDefaults.standard.removeObject(forKey: kNeedCaptcha)}
        else { UserDefaults.standard.setValue(needCaptcha, forKey: kNeedCaptcha)}
        UserDefaults.standard.synchronize()
    }
}
