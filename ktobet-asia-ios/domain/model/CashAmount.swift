import Foundation
import SharedBu

extension CashAmount {
    var displayAmount:String {
        if self.amount >= 0 {
            return floorAmount
        } else {
            return absFloorAmount
        }
    }
    
    var floorAmount: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.groupingSeparator = ","
        numberFormatter.groupingSize = 3
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.decimalSeparator = "."
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.roundingMode = .down
        
        return numberFormatter.string(from: self.amount as NSNumber) ?? ""
    }
    
    var absFloorAmount: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.groupingSeparator = ","
        numberFormatter.groupingSize = 3
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.decimalSeparator = "."
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.roundingMode = .down
        
        return numberFormatter.string(from: abs(self.amount) as NSNumber) ?? ""
    }
}
