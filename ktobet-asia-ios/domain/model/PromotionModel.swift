import Foundation
import SharedBu
import UIKit

extension BonusCoupon.FreeBet: HasAmountLimitationItem {
  var displayBetMultiple: String {
    self.betMultiple.description
  }

  var displayPercentage: String {
    self.percentage.description()
  }

  var displayMaxAmount: String {
    self.maxAmount.formatString()
  }

  var displayMinCapital: String {
    self.minCapital.description()
  }

  var displayLevel: String? {
    "0"
  }

  var displayInformPlayerDate: String {
    self.informPlayerDate.toDateString()
  }

  var icon: String {
    "iconLv48"
  }

  var id: String {
    self.promotionId
  }

  var displayAmount: String {
    maxAmount.formatString()
  }

  var issueNo: String {
    ""
  }

  var title: String {
    Localize.string("bonus_bonustype_1")
  }

  var subTitle: String {
    ""
  }

  var message: String {
    name
  }

  var couponState: CouponStatus {
    self.couponStatus
  }

  var rawValue: BonusCoupon {
    self
  }
}

extension BonusCoupon.DepositReturn: HasAmountLimitationItem {
  var displayBetMultiple: String {
    self.betMultiple.description
  }

  var displayPercentage: String {
    self.percentage.description()
  }

  var displayMaxAmount: String {
    self.maxAmount.formatString()
  }

  var displayMinCapital: String {
    self.minCapital.description()
  }

  var displayLevel: String? {
    "0"
  }

  var displayInformPlayerDate: String {
    self.informPlayerDate.toDateString()
  }

  var icon: String {
    "iconLvDepositBonus48Big"
  }

  var id: String {
    self.promotionId
  }

  var displayAmount: String {
    var suffix: String
    if maxAmount.isUnlimited() {
      suffix = Localize.string("bonus_rebate_unlimited")
    }
    else {
      suffix = maxAmount.formatString()
    }
    return Localize.string("bonus_gettop") + "\n\(suffix)"
  }

  var issueNo: String {
    ""
  }

  var title: String {
    Localize.string("bonus_bonustype_2")
  }

  var subTitle: String {
    ""
  }

  var message: String {
    name
  }

  var couponState: CouponStatus {
    self.couponStatus
  }

  var rawValue: BonusCoupon {
    self
  }
}

extension BonusCoupon.Product: BonusCouponItem {
  var displayBetMultiple: String {
    self.betMultiple.description
  }

  var displayPercentage: String {
    "0"
  }

  var displayMaxAmount: String {
    self.maxAmount.formatString()
  }

  var displayMinCapital: String {
    self.minCapital.description()
  }

  var displayLevel: String? {
    "0"
  }

  var displayInformPlayerDate: String {
    self.informPlayerDate.toDateString()
  }

  var icon: String {
    ""
  }

  var id: String {
    self.promotionId
  }

  var displayAmount: String {
    maxAmount.formatString()
  }

  var issueNo: String {
    Localize.string("bonus_period", "\(issueNumber)")
  }

  var title: String {
    Localize.string("bonus_bonustype_3")
  }

  var subTitle: String {
    convertToLocalize(forProduct: productType)
  }

  var message: String {
    convertToLocalize(forProduct: productType)
  }

  var couponState: CouponStatus {
    self.couponStatus
  }

  var rawValue: BonusCoupon {
    self
  }
}

extension PromotionEvent.Product: PromotionEventItem {
  var displayMaxAmount: String {
    if maxBonus.isUnlimited() {
      return Localize.string("bonus_rebate_unlimited")
    }
    else {
      return maxBonus.formatString()
    }
  }

  var displayPercentage: String {
    "0"
  }

  var displayLevel: String? {
    nil
  }

  var displayInformPlayerDate: String {
    self.informPlayerDate.toDateFormatString()
  }

  var icon: String {
    ""
  }

  var rawValue: PromotionEvent {
    self
  }

  var id: String {
    self.promotionId
  }

  func isAutoUse() -> Bool {
    false
  }

  var expireDate: Date {
    endDate.convertToDate()
  }

  var displayAmount: String {
    if maxBonus.isUnlimited() {
      return Localize.string("bonus_rebate_unlimited")
    }
    else {
      let suffix = maxBonus.formatString()
      return Localize.string("bonus_gettop") + "\n\(suffix)"
    }
  }

  var issueNo: String {
    Localize.string("bonus_period", "\(issueNumber)")
  }

  var title: String {
    Localize.string("bonus_bonustype_3")
  }

  var subTitle: String {
    convertToLocalize(forProduct: type)
  }

  var message: String {
    convertToLocalize(forProduct: type)
  }
}

func convertToLocalize(forProduct productType: ProductType) -> String {
  switch productType {
  case .slot:
    return Localize.string("bonus_bonusproducttype_2")
  case .sbk:
    return Localize.string("bonus_bonusproducttype_1")
  default:
    return ""
  }
}

extension BonusCoupon.Rebate: BonusCouponItem {
  var displayBetMultiple: String {
    self.betMultiple.description
  }

  var displayPercentage: String {
    self.percentage.description()
  }

  var displayMaxAmount: String {
    self.amount.description()
  }

  var displayMinCapital: String {
    self.minCapital.description()
  }

  var displayLevel: String? {
    "0"
  }

  var displayInformPlayerDate: String {
    self.informPlayerDate.toDateString()
  }

  var icon: String {
    "iconLvCashBack48Big"
  }

  var id: String {
    self.promotionId
  }

  var displayAmount: String {
    self.amount.description()
  }

  var issueNo: String {
    if let num = issueNumber {
      return Localize.string("bonus_period", "\(num)")
    }
    else {
      return Localize.string("bonus_period", "")
    }
  }

  var title: String {
    Localize.string("bonus_bonustype_4")
  }

  var subTitle: String {
    ""
  }

  var message: String {
    Localize.string(
      "bonus_rebate_title",
      StringMapper.parseProductTypeString(productType: rebateFrom),
      percentage.description())
  }

  var couponState: CouponStatus {
    self.couponStatus
  }

  var rawValue: BonusCoupon {
    self
  }
}

extension PromotionEvent.Rebate: PromotionEventItem {
  var displayMaxAmount: String {
    if maxBonus.isUnlimited() {
      return Localize.string("bonus_rebate_unlimited")
    }
    else {
      return maxBonus.formatString()
    }
  }

  var displayPercentage: String {
    self.percentage.description()
  }

  var displayLevel: String? {
    nil
  }

  var displayInformPlayerDate: String {
    self.informPlayerDate.toDateFormatString()
  }

  var icon: String {
    "iconLvCashBack48Big"
  }

  var id: String {
    self.promotionId
  }

  func isAutoUse() -> Bool {
    self.isAutoUse
  }

  var expireDate: Date {
    endDate.convertToDate()
  }

  var displayAmount: String {
    if maxBonus.isUnlimited() {
      return Localize.string("bonus_rebate_unlimited")
    }
    else {
      let suffix = maxBonus.formatString()
      return Localize.string("bonus_gettop") + "\n\(suffix)"
    }
  }

  var issueNo: String {
    Localize.string("bonus_period", "\(issueNumber)")
  }

  var title: String {
    Localize.string("bonus_bonustype_4")
  }

  var subTitle: String {
    ""
  }

  var message: String {
    Localize.string(
      "bonus_rebate_title",
      StringMapper.parseProductTypeString(productType: type),
      percentage.description())
  }
}

extension BonusCoupon.VVIPCashback: BonusCouponItem {
  var stampIcon: String {
    "iconCrown"
  }

  var displayBetMultiple: String {
    self.betMultiple.description
  }

  var displayPercentage: String {
    ""
  }

  var displayMaxAmount: String {
    self.amount.description()
  }

  var displayMinCapital: String {
    self.minCapital.description()
  }

  var displayLevel: String? {
    "0"
  }

  var displayInformPlayerDate: String {
    self.informPlayerDate.toDateString()
  }

  var icon: String {
    "iconVVIPCashBack48Big"
  }

  var id: String {
    self.promotionId
  }

  var displayAmount: String {
    self.amount.description()
  }

  var issueNo: String {
    if let num = issueNumber {
      return Localize.string("bonus_period", "\(num)")
    }
    else {
      return Localize.string("bonus_period", "")
    }
  }

  var title: String {
    Localize.string("bonus_bonustype_7")
  }

  var subTitle: String {
    ""
  }

  var message: String {
    Localize.string("bonus_bonustype_7")
  }

  var couponState: CouponStatus {
    self.couponStatus
  }

  var rawValue: BonusCoupon {
    self
  }
}

extension PromotionEvent.VVIPCashback: PromotionEventItem {
  var stampIcon: String {
    "iconCrown"
  }

  var displayMaxAmount: String {
    maxBonus.formatString()
  }

  var displayPercentage: String {
    self.percentage.description()
  }

  var displayLevel: String? {
    nil
  }

  var displayInformPlayerDate: String {
    self.informPlayerDate.toDateFormatString()
  }

  var icon: String {
    "iconVVIPCashBack48Big"
  }

  var id: String {
    self.promotionId
  }

  func isAutoUse() -> Bool {
    false
  }

  var expireDate: Date {
    endDate.convertToDate()
  }

  var displayAmount: String {
    Localize.string("bonus_gettop") + "\n\(maxBonus.formatString())"
  }

  var issueNo: String {
    Localize.string("bonus_period", "\(issueNumber)")
  }

  var title: String {
    Localize.string("bonus_bonustype_7")
  }

  var subTitle: String {
    ""
  }

  var message: String {
    Localize.string("bonus_bonustype_7")
  }
}
