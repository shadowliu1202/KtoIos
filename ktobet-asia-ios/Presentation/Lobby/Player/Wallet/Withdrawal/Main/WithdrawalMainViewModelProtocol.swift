import Foundation
import sharedbu
import UIKit

protocol WithdrawalMainViewModelProtocol {
  var instruction: WithdrawalMainViewDataModel.Instruction? { get }
  var recentRecords: [WithdrawalMainViewDataModel.Record]? { get }

  var enableWithdrawal: Bool { get }
  var allowedWithdrawalFiat: Bool? { get }
  var allowedWithdrawalCrypto: Bool? { get }

  func setupData()
}

struct WithdrawalMainViewDataModel {
  struct Instruction {
    let dailyAmountLimit: String
    let dailyMaxCount: String
    let turnoverRequirement: String?
    let cryptoWithdrawalRequirement: (amount: String, simpleName: String)?
  }

  struct Record: Identifiable, Equatable {
    let id: String
    let currencyType: WithdrawalDto.LogCurrencyType
    let date: String
    let status: TransactionStatus
    let amount: String

    static func == (lhs: WithdrawalMainViewDataModel.Record, rhs: WithdrawalMainViewDataModel.Record) -> Bool {
      lhs.id == rhs.id
    }
  }

  struct TransactionStatus {
    let title: String
    let color: UIColor
  }
}
