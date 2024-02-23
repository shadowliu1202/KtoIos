import sharedbu

extension BonusType {
  static func convert(_ type: Int32) -> BonusType {
    BonusType.convertToBonusType(type).1
  }

  static func convert(_ type: BonusType) -> Int32 {
    BonusType.convertToBonusType(type).0
  }

  private static func convertToBonusType(_ type: Any) -> (Int32, BonusType) {
    let bonusTypeValues: [Int32: BonusType] = [
      1: .freeBet,
      2: .depositBonus,
      3: .product,
      4: .rebate,
      5: .levelBonus,
      7: .vvipcashback
    ]
    switch type {
    case let id as Int32:
      if let bonusType = bonusTypeValues[id] {
        return (id, bonusType)
      }
    case let bonusType as BonusType:
      if let id = bonusTypeValues.first(where: { $0.value == bonusType })?.key {
        return (id, bonusType)
      }
    default:
      break
    }
    return (-1, .other)
  }
}
