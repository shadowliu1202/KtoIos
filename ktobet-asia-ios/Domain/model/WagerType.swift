import sharedbu

extension WagerType {
  class func convert(_ type: Int32) -> WagerType {
    WagerType.convertToWagerType(type).1
  }

  private class func convertToWagerType(_ type: Any) -> (Int32, WagerType) {
    switch type {
    case let b as WagerType:
      switch b {
      case .outright: return (0, WagerType.outright)
      case .single: return (1, WagerType.single)
      case .parlay: return (2, WagerType.parlay)
      default: return (-1, WagerType.unknown)
      }
    case let i as Int32:
      switch i {
      case 0: return (0, WagerType.outright)
      case 1: return (1, WagerType.single)
      case 2: return (2, WagerType.parlay)
      default: return (-1, WagerType.unknown)
      }
    default: return (-1, WagerType.unknown)
    }
  }
}

extension TransactionModes {
  class func convert(_ type: Int32) throws -> TransactionModes {
    try TransactionModes.convertToTransactionModes(type).1
  }

  private class func convertToTransactionModes(_ type: Any) throws -> (Int32, TransactionModes) {
    switch type {
    case let b as TransactionModes:
      switch b {
      case .normal: return (0, TransactionModes.normal)
      case .smartbet: return (1, TransactionModes.smartbet)
      case .tips: return (2, TransactionModes.tips)
      case .eventbonus: return (3, TransactionModes.eventbonus)
      default: throw TransactionModesError.unknownMode
      }
    case let i as Int32:
      switch i {
      case 0: return (0, TransactionModes.normal)
      case 1: return (1, TransactionModes.smartbet)
      case 2: return (2, TransactionModes.tips)
      case 3: return (2, TransactionModes.eventbonus)
      default: throw TransactionModesError.unknownMode
      }
    default: throw TransactionModesError.unknownMode
    }
  }

  enum TransactionModesError: Error {
    case unknownMode
  }
}
