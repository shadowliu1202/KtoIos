//
//  TermsData.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/27.
//

struct TermsOfService {
    enum type {
        case header
        case body
    }
    var title = ""
    var content = ""
    var selected = false
    var type = TermsOfService.type.body
}
