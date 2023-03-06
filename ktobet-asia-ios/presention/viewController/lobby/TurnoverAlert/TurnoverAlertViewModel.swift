import SharedBu
import SwiftUI
import UIKit

protocol TurnoverAlertViewModelProtocol {
  var detail: TurnoverAlertDataModel.Detail { get }
  var locale: SupportLocale { get }

  func prepareForAppear(situation: TurnoverAlertDataModel.Situation, turnover: TurnOverDetail)
}

class TurnoverAlertViewModel:
  TurnoverAlertViewModelProtocol,
  ObservableObject
{
  @Published var detail: TurnoverAlertDataModel.Detail = .init()

  let locale: SupportLocale

  init(locale: SupportLocale) {
    self.locale = locale
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  func prepareForAppear(situation: TurnoverAlertDataModel.Situation, turnover: TurnOverDetail) {
    detail = .init(
      headerTitle: getHeaderTitle(
        situation,
        receiveBonusDate: turnover.informPlayerDate.toDateTimeString()),
      turnoverName: turnover.name,
      receiveAmount: turnover.parameters.amount.description(),
      totalBetRequest: turnover.parameters.turnoverRequest.description(),
      remainBetRequest: turnover.remainAmount.description(),
      percentage: turnover.parameters.percentage.description(),
      ratio: turnover.parameters.percentage.percent / 100)
  }

  private func getHeaderTitle(
    _ situation: TurnoverAlertDataModel.Situation,
    receiveBonusDate: String)
    -> String
  {
    switch situation {
    case .intoGame(let gameName):
      return String(
        format: Localize.string("product_turnover_description"),
        arguments: [
          gameName,
          receiveBonusDate
        ])
    case .useCoupon:
      return String(
        format: Localize.string("bonus_turnover_confirm_title"),
        receiveBonusDate)
    }
  }
}

// MARK: - DataModel

struct TurnoverAlertDataModel {
  enum Situation {
    case intoGame(gameName: String)
    case useCoupon
  }

  struct Detail {
    var headerTitle = "-"
    var turnoverName = "-"
    var receiveAmount = "-"
    var totalBetRequest = "-"
    var remainBetRequest = "-"
    var percentage = "-"
    var ratio: Double = 0
  }
}
