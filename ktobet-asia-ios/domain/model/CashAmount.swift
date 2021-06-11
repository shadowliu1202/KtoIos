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
    
    static func productTotalBet(betAmount: CashAmount, winLoss: CashAmount?) -> String {
        if let winLoss = winLoss, winLoss.amount != 0 {
            let status = winLoss.isPositive() ? Localize.string("common_win") : Localize.string("common_lose")
            return Localize.string("product_total_bet", betAmount.displayAmount) + "  " + status + " \(winLoss.displayAmount)"
        } else {
            return Localize.string("product_total_bet", betAmount.displayAmount)
        }
    }
}
