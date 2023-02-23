import SharedBu

extension DepositSystem {
  static func create() -> DepositSystem {
    let list = NSMutableArray()
    for index in 0..<SupportCryptoType.values().size {
      list.add(SupportCryptoType.values().get(index: index) as Any)
    }
    /// 因為BBU-1016所以剔除usdc
    let supports = list.compactMap({ $0 as? SupportCryptoType }).filter({ $0 != SupportCryptoType.usdc })
    return DepositSystem.companion.create(supportCryptos: supports)
  }
}
