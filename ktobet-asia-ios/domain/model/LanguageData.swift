//
//  LanguageData.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/27.
//

import share_bu


struct Language {
    enum LanguageType {
        case chinese
        case vietnamese
    }
    var type : LanguageType = .chinese
    var name : String {
        get{
            switch type {
            case .chinese: return "cn"
            case .vietnamese: return "vn"
            }
        }
    }
}
