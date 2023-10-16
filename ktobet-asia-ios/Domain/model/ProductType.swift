import sharedbu

extension ProductType {
  class func convert(_ type: Int) -> ProductType {
    ProductType.convertToProductType(Int32(type)).1
  }

  class func convert(_ type: Int32) -> ProductType {
    ProductType.convertToProductType(type).1
  }

  class func convert(_ type: ProductType) -> Int32 {
    ProductType.convertToProductType(type).0
  }

  private class func convertToProductType(_ type: Any) -> (Int32, ProductType) {
    switch type {
    case let p as ProductType:
      switch p {
      case .sbk: return (1, ProductType.sbk)
      case .slot: return (2, ProductType.slot)
      case .casino: return (3, ProductType.casino)
      case .numbergame: return (4, ProductType.numbergame)
      case .p2p: return (5, ProductType.p2p)
      case .arcade: return (6, ProductType.arcade)
      default: return (0, ProductType.none)
      }
    case let i as Int32:
      switch i {
      case 1: return (1, ProductType.sbk)
      case 2: return (2, ProductType.slot)
      case 3: return (3, ProductType.casino)
      case 4: return (4, ProductType.numbergame)
      case 5: return (5, ProductType.p2p)
      case 6: return (6, ProductType.arcade)
      default: return (0, ProductType.none)
      }
    default: return (0, ProductType.none)
    }
  }
}
