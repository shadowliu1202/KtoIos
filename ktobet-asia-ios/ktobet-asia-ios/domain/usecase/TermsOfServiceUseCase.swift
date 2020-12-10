//
//  TermsOfServiceUseCase.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/27.
//

import Foundation
import RxCocoa
import RxDataSources


class TermsOfServiceUseCase {
    
    var languageRepository : LanguageRepository!
    
    init(_ languageRepo : LanguageRepository) {
        self.languageRepository = languageRepo
    }
    
    func termsOfService()->[[TermsOfService]]{
        
        let header = languageRepository.localized("Warning")
        let titles = [languageRepository.localized("Definition"),
                      languageRepository.localized("Agree"),
                      languageRepository.localized("Modify")]
        
        let contents = [languageRepository.localized("Definition_Content"),
                        languageRepository.localized("Agree_Content"),
                        languageRepository.localized("Modify_Content")]
        
        let arr : [[TermsOfService]] = [{
            var item = TermsOfService()
            item.title = ""
            item.content = header
            item.selected = false
            item.type = .header
            return [item]
        }(),{
            guard titles.count == contents.count && titles.count > 0 else {
                return []
            }
            var arr2 = [TermsOfService]()
            for idx in 0..<titles.count{
                arr2.append({
                    var item = TermsOfService()
                    item.title = titles[idx]
                    item.content = contents[idx]
                    item.selected = false
                    item.type = .body
                    return item
                }())
            }
            return arr2
        }()]
        return arr
    }
}
