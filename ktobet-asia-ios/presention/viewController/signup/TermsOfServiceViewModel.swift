//
//  TermsOfServiceViewModel.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/2.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources


class TermsOfServiceViewModel {
    
    private var termsUseCase : TermsOfServiceUseCase!
    lazy private var arrTerms = self.termsOfService()
    lazy var repoTerms = BehaviorSubject<[SectionModel<Int, TermsOfService>]>(value: arrTerms)

    init( _ termsUseCase : TermsOfServiceUseCase) {
        self.termsUseCase = termsUseCase
    }
    
    private func termsOfService()->[SectionModel<Int, TermsOfService>]{
        let arr = termsUseCase.termsOfService()
        guard arr.count > 0 else {
            return []
        }
        var result = [SectionModel<Int, TermsOfService>]()
        for idx in 0..<arr.count{
            result.append({
                return SectionModel(model: idx, items: arr[idx])
            }())
        }
        return result
    }
    
    
    func termSelected(_ section: Int, _ row: Int){
        guard section < arrTerms.count && row < arrTerms[section].items.count else { return }
        arrTerms[section].items[row].selected = !arrTerms[section].items[row].selected
        self.repoTerms.onNext(arrTerms)
    }
}
