import SharedBu

class DepositTypeFactory {
    class func create(id: Int32, name: String, min: CashAmount, max: CashAmount, isFavorite: Bool) -> DepositRequest.DepositType {
        switch id {
        case 0:
            return DepositRequest.DepositTypeOffline(id: id, name: name, min: min, max: max, isFavorite: isFavorite)
        case 1...3, 5, 6, 11:
            return DepositRequest.DepositTypeThirdParty(id: id, name: name, min: min, max: max, isFavorite: isFavorite, hasRedirection: false, hint: "")
        case 14:
            return DepositRequest.DepositTypeThirdParty(id: id, name: name, min: min, max: max, isFavorite: isFavorite, hasRedirection: false, hint: Localize.string("deposit_pay_multiple_hint"))
        case 2001:
            return DepositRequest.DepositTypeCrypto(id: id, name: name, min: min, max: max, isFavorite: isFavorite)
        default:
            return DepositRequest.DepositTypeUnknown()
        }
    }
}
