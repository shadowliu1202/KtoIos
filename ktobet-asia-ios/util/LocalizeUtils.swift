//
//  LocalizeUtils.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/12/14.
//

import Foundation
import SharedBu

let Localize = LocalizeUtils.shared

class LocalizeUtils: NSObject {
    static let shared = LocalizeUtils()
    
    func string(_ key: String, _ parameters: [String]) -> String {
        let localizationFileNmae = getLanguage()
        let path = Bundle.main.path(forResource: localizationFileNmae, ofType: "lproj")
        let bundle = Bundle(path: path!)
        return String(format: NSLocalizedString(key, tableName: nil, bundle: bundle!, value: "", comment: ""), arguments: parameters)
    }
    
    func string(_ key: String, _ parameters: String...) -> String {
        let localizationFileNmae = getLanguage()
        let path = Bundle.main.path(forResource: localizationFileNmae, ofType: "lproj")
        let bundle = Bundle(path: path!)
        return String(format: NSLocalizedString(key, tableName: nil, bundle: bundle!, value: "", comment: ""), arguments: parameters)
    }
    
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
    
    func getSymbol(locale: Locale = Locale(identifier: "zh_Hans_CN")) -> String? {
        let lang = UserDefaults.standard.string(forKey: "UserLanguage")
        switch lang {
        case Language.ZH.rawValue: return Locale(identifier: "zh_Hans_CN").currencySymbol
        case Language.TH.rawValue: return Locale(identifier: "th_TH").currencySymbol
        case Language.VI.rawValue: return Locale(identifier: "vi_VN").currencySymbol
        default:
            return ""
        }
    }
}

extension LocalizeUtils: StringSupporter {
    func convert(resourceId: ResourceKey, args: KotlinArray<AnyObject>) -> KotlinLazy {
        let key = resourceId.asString()
        if args.size > 0 {
            var parameters: [String] = []
            for idx in 0..<args.size {
                if let num = args.get(index: idx), num is Double || num is Int32 {
                    parameters.append("\(num)")
                } else if let str = args.get(index: idx), str is String {
                    parameters.append(str as! String)
                } else if let cashAmount = args.get(index: idx), cashAmount is CashAmount {
                    let amount = cashAmount as! CashAmount
                    parameters.append(amount.description())
                } else if let unknown = args.get(index: idx) {
                    print(">>>>>>>StringSupporter unknown type arg: \(type(of: unknown))")
                    fatalError("please implements it")
                } else {
                    print(">>>>>>>StringSupporter option type arg: \(type(of: args.get(index: idx)))")
                }
            }
            return KNLazyCompanion.init().create(input: self.string(key, parameters))
        } else {
            return KNLazyCompanion.init().create(input: self.string(key))
        }
    }
    
    func convert(resourceId: ResourceKey) -> KotlinLazy {
        let key = resourceId.asString()
        return KNLazyCompanion.init().create(input: self.string(key))
    }
}
