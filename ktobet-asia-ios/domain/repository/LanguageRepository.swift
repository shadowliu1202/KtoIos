//
//  languageRepository.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/27.
//

import RxSwift


// MARK: Define
protocol LanguageRepository {
    func localized(_ key : String)-> String
}


class LanguageRepositoryImpl: LanguageRepository {
    
    // MARK: Property
    var language : Language!{
        didSet{
            setupLanguageMap()
        }
    }
    private var languageMap : [String : String] = [:]
    
    // MARK: initilaize
    init(_ language : Language) {
        self.language = language
        setupLanguageMap()
    }
    
    // MARK: Method
    private func setupLanguageMap(){
        guard let path = Bundle.main.url(forResource: language.name, withExtension: "json"),
              let data = try? Data(contentsOf: path),
              let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : String] else{
            languageMap = [:]
            return
        }
        languageMap = dict
    }
    
    // MARK: Implememnt
    func localized(_ key : String)-> String  {
        let str = languageMap[key] ?? ""
        return str
    }
}
