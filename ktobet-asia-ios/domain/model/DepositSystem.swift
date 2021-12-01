import SharedBu

extension DepositSystem {
    static func create() -> DepositSystem {
/*因為BBU-1016所以先註解
        let list = NSMutableArray()
        for index in 0..<SupportCryptoType.values().size {
            list.add(SupportCryptoType.values().get(index: index) as Any)
        }
        let supports = list.compactMap({$0 as? SupportCryptoType})
 */
        let supports = [SupportCryptoType.usdt, SupportCryptoType.eth]
        return DepositSystem.companion.create(supportCryptos: supports)
    }
}
