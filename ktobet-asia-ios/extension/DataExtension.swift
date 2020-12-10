//
//  DataExtension.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/12.
//

import Foundation

extension Data {
    var prettyJSON: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyJSON = String(data: data, encoding: .utf8) else {
            return nil
        }
        return prettyJSON
    }
}
