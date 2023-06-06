import SharedBu

extension WithdrawalSystem {
  static func create() -> WithdrawalSystem {
    let list = NSMutableArray()
    for index in 0..<SupportCryptoType.values().size {
      list.add(SupportCryptoType.values().get(index: index) as Any)
    }
    /// 因為BBU-1016所以剔除usdc
    let tempArray = list.compactMap({ $0 as? SupportCryptoType }).filter({ $0 != SupportCryptoType.usdc })
    let tempWithdrawal = WithdrawalSystem.companion.create(supportCryptos: tempArray)
    let recommend: KotlinComparator = tempWithdrawal.recommendCrypto()
    let supports = tempArray.sorted(by: { a, b in
      recommend.compare(a: a, b: b) < 0
    })
    return WithdrawalSystem.companion.create(supportCryptos: supports)
  }
}
