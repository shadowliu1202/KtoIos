import SharedBu

extension Crypto.Ethereum {
    static func create() -> Crypto {
        return Crypto.Companion.init().create(simpleName: Crypto.Ethereum.init().simpleName)
    }
}
