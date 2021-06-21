import SharedBu

extension CryptoAmount {
    static func create(cryptoAmount: Double, crypto: Crypto) -> CryptoAmount {
        return CryptoAmount.Companion.init().create(cryptoAmount: cryptoAmount, crypto: crypto)
    }
}
