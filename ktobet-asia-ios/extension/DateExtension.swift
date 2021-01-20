//
//  DateExtension.swift
//  ktobet-asia-ios
//
//  Created by Weichen Cheng on 2021/1/6.
//

import Foundation


extension Date {
    func adding(value: Int, byAdding: Calendar.Component) -> Date {
        return Calendar.current.date(byAdding: byAdding, value: value, to: self)!
    }
}
