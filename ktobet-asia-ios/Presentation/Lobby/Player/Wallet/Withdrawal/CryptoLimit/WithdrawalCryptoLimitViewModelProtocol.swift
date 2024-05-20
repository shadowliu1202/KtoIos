import Foundation

protocol WithdrawalCryptoLimitViewModelProtocol {
    var remainRequirement: String? { get }
    var summaryRequirement: WithdrawalCryptoLimitDataModel.Summary? { get }
    var summaryAchieved: WithdrawalCryptoLimitDataModel.Summary? { get }

    func setupData()
}

struct WithdrawalCryptoLimitDataModel {
    struct Summary {
        let title: String
        let records: [WithdrawalCryptoLimitDataModel.Record]
    }

    struct Record: Identifiable, Equatable {
        let id: String
        let dateTime: String
        let fiatAmount: String
        let cryptoAmount: String

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
    }
}
