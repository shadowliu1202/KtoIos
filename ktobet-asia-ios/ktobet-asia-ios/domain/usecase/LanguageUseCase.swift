//
//  LanguageUseCase.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/27.
//

import Foundation


class LanguageUseCase {
    
    var languageRepository : LanguageRepository!
    
    init(_ languageRepo : LanguageRepository) {
        languageRepository = languageRepo
    }
    
    func localized(_ key : String)-> String {
        return languageRepository.localized(key)
    }
    
}
