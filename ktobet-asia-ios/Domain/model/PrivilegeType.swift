import sharedbu

extension PrivilegeType {
  static func convert(_ type: Int32) -> PrivilegeType {
    PrivilegeType.convertToPrivilegeType(type).1
  }

  static func convert(_ type: PrivilegeType) -> Int32 {
    PrivilegeType.convertToPrivilegeType(type).0
  }

  private static func convertToPrivilegeType(_ type: Any) -> (Int32, PrivilegeType) {
    let dictionary: [Int32: PrivilegeType] = [
      1: PrivilegeType.freebet,
      2: PrivilegeType.depositBonus,
      3: PrivilegeType.product,
      4: PrivilegeType.rebate,
      5: PrivilegeType.levelBonus,
      7: PrivilegeType.vvipcashBack,
      90: PrivilegeType.feedback,
      91: PrivilegeType.withdrawal,
      92: PrivilegeType.domain
    ]
    
    switch type {
    case let value as PrivilegeType:
      if let id = dictionary.first(where: { $0.value == value })?.key {
        return (id, value)
      }

    case let key as Int32:
      if let value = dictionary[key] {
        return (key, value)
      }
    default: break
    }
    return (0, PrivilegeType.none)
  }
}
