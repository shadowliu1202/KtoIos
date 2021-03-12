//
//  DepositPresenter.swift
//  ktobet-asia-ios
//
//  Created by LeoOnHiggstar on 2021/3/6.
//

import UIKit
import share_bu

class DepositPresenter: FilterPresentProtocol {
    private var conditions = [FilterItemFactor.create(.static),
                              FilterItemFactor.create(.interactive(status: .approved)),
                              FilterItemFactor.create(.interactive(status: .reject)),
                              FilterItemFactor.create(.interactive(status: .pending)),
                              FilterItemFactor.create(.interactive(status: .floating))]
    
    func getTitle() -> String {
        return Localize.string("common_filter")
    }
    func setConditions(_ items: [FilterItem]) {
        conditions = items
    }
    func getDatasource() -> [FilterItem] {
        return conditions
    }
}

class FilterItemFactor {
    class func create(_ category: FilterItem.Display) -> FilterItem {
        switch category {
        case .static:
            return FilterItem(type: .static, title: Localize.string("common_statusfilter"), select: false)
        case .interactive(let status):
            return FilterItem(type: .interactive(status: status), title: TransactionStatusFactor.title(status), select: true)
        }
    }
}
