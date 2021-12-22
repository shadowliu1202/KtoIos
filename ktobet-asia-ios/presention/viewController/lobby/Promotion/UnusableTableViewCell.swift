import UIKit
import SharedBu

class UnusableTableViewCell: PromotionTableViewCell {

    override func prepareForReuse() {
        super.prepareForReuse()
        watermarkIcon.image = nil
    }
    
    func configure(_ item: PromotionVmItem, _ isFull: Bool = false) -> Self {
        super.setData(item)
        if let limitationItem = item as? HasAmountLimitationItem {
            watermarkIcon.image = limitationItem.watermarkIcon
        }
        return self
    }
    
    override func configureValidPeriodLayout(_ now: Date, _ period: ValidPeriod.Duration) {
        btnGetCouponHeight.constant = 0
        btnGetCoupon.setTitle(nil, for: .normal)
        timerLabel.textAlignment = .left
    }
}
