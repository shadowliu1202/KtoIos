import Foundation
import SharedBu
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
    
    func parse(bonusReceivingStatus: BonusReceivingStatus) -> UIColor {
        switch bonusReceivingStatus {
        case .inprogress:
            return UIColor.orangeFull
        case .noturnover:
            return UIColor.textSuccessedGreen
        case .completed:
            return UIColor.textSuccessedGreen
        case .canceled:
            return UIColor.textPrimaryDustyGray
        default:
            return UIColor.clear
        }
    }
}
