import sharedbu

extension ProductType {
  static func convert(_ type: Int) -> ProductType {
    ProductType.convertToProductType(Int32(type)).1
  }

  static func convert(_ type: Int32) -> ProductType {
    ProductType.convertToProductType(type).1
  }

  static func convert(_ type: ProductType) -> Int32 {
    ProductType.convertToProductType(type).0
  }

  private static func convertToProductType(_ type: Any) -> (Int32, ProductType) {
    let dictionary: [Int32: ProductType] = [
      1: ProductType.sbk,
      2: ProductType.slot,
      3: ProductType.casino,
      4: ProductType.numberGame,
      5: ProductType.p2P,
      6: ProductType.arcade
    ]
    
    switch type {
    case let value as ProductType:
      if let id = dictionary.first(where: { $0.value == value })?.key {
        return (id, value)
      }

    case let key as Int32:
      if let value = dictionary[key] {
        return (key, value)
      }
    default: break
    }
    return (0, ProductType.none)
  }
}
