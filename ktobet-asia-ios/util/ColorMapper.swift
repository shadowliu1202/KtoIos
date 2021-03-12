import Foundation
import share_bu
import UIKit

class ColorMapper {
    static let sharedInstance = ColorMapper()
    private init() { }
    
    func parse(_ transactionStatus: TransactionStatus) -> UIColor {
        switch transactionStatus {
        case .floating:
            return UIColor.orangeFull
        default:
            return UIColor.textPrimaryDustyGray
        }
    }
}
