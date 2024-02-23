import sharedbu
import UIKit

class UnusableTableViewCell: PromotionTableViewCell {
  override func prepareForReuse() {
    super.prepareForReuse()
    watermarkIcon.image = nil
  }

  func configure(_ item: PromotionVmItem, _ local: SupportLocale) -> Self {
    super.setData(item)
    if let limitationItem = item as? HasAmountLimitation {
      watermarkIcon.image = getWatermarkIcon(limitationItem, local)
    }
    return self
  }

  override func configureValidPeriodLayout(_: ValidPeriod.Duration) {
    btnGetCouponHeight.constant = 0
    btnGetCoupon.setTitle(nil, for: .normal)
    timerLabel.textAlignment = .left
  }

  private func getWatermarkIcon(_ item: HasAmountLimitation, _ local: SupportLocale) -> UIImage? {
    switch item.getFullType() {
    case .none:
      return nil
    case .daily:
      return Theme.shared.getUIImage(name: "promotionDailyFull", by: local)
    case .complete:
      return Theme.shared.getUIImage(name: "promotionIsFull", by: local)
    }
  }
}
