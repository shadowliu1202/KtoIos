//
//  FilterPresentProtocol.swift
//  ktobet-asia-ios
//
//  Created by LeoOnHiggstar on 2021/3/6.
//

import UIKit
import share_bu

protocol FilterPresentProtocol {
    func getTitle() -> String
    func getDatasource() -> [FilterItem]
    func setConditions(_ items: [FilterItem])
    func getConditionStatus(_ items: [FilterItem]) -> [TransactionStatus]
}

extension FilterPresentProtocol {
    func getConditionStatus(_ items: [FilterItem]) -> [TransactionStatus] {
        return items.filter({ $0.isSelected == true }).map({$0.status!})
    }
}

struct FilterItem {
    enum Display: Equatable {
        case `static`
        case interactive(status: TransactionStatus)
        static func == (lhs: Display, rhs: Display) -> Bool {
            switch (lhs, rhs) {
            case (.static, .static):
                return true
            case (.interactive(let lhsStatus), .interactive(let rhsStatus)):
                return lhsStatus == rhsStatus
            default:
                return false
            }
        }
    }
    var type: Display
    var title: String
    private var select: Bool? = false
    var isSelected: Bool? {
        set{
            select = newValue
        }
        get {
            switch type {
            case .static:
                return nil
            case .interactive(_):
                return select
            }
        }
    }
    var image: UIImage? {
        return select ?? false ? UIImage(named: "Double Selection (Selected)") : UIImage(named: "Double Selection (Empty)")
    }
    
    init(type: Display, title: String, select: Bool) {
        self.type = type
        self.title = title
        self.select = select
    }
   
    var status: TransactionStatus? {
        switch type {
        case .static:
            return nil
        case .interactive(let status):
            return status
        }
    }
}
