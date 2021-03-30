//
//  LocalizeUtils.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/14.
//

import Foundation


let Localize = LocalizeUtils.shared

class LocalizeUtils: NSObject {
    static let shared = LocalizeUtils()
    
    func string(_ key: String, _ parameter: String? = nil) -> String {
        let localizationFileNmae = getLanguage()
        let path = Bundle.main.path(forResource: localizationFileNmae, ofType: "lproj")
        let bundle = Bundle(path: path!)
        if let parameter = parameter {
            return String(format: NSLocalizedString(key, tableName: nil, bundle: bundle!, value: "", comment: ""), parameter)
        }else {
            return NSLocalizedString(key, tableName: nil, bundle: bundle!, value: "", comment: "")
        }
    }
    
    func setLanguage(language : Language){
        let lang = language.rawValue
        UserDefaults.standard.setValue(lang, forKey: "UserLanguage")
    }
    
    func getLanguage()-> String{
        let lang = UserDefaults.standard.string(forKey: "UserLanguage")
        switch lang {
        case Language.ZH.rawValue: return lang!
        case Language.TH.rawValue: return lang!
        case Language.VI.rawValue: return lang!
        default:
            UserDefaults.standard.setValue(Language.ZH.rawValue, forKey: "UserLanguage")
            return Language.ZH.rawValue
        }
    }
}
