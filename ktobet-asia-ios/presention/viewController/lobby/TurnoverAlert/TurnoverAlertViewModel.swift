import SharedBu
import SwiftUI
import UIKit

protocol TurnoverAlertViewModelProtocol {
  var detail: TurnoverAlertViewModel.Detail { get }
  var locale: SupportLocale { get }

  func prepareForAppear(gameName: String, turnover: TurnOverDetail)
}

class TurnoverAlertViewModel: TurnoverAlertViewModelProtocol,
  ObservableObject
{
  @Published var detail: Detail = .init()

  let locale: SupportLocale

  init(locale: SupportLocale) {
    self.locale = locale
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  func prepareForAppear(gameName: String, turnover: TurnOverDetail) {
    detail = .init(
      gameName: gameName,
      receiveBonusDate: turnover.informPlayerDate.toDateTimeString(),
      turnoverName: turnover.name,
      receiveAmount: turnover.parameters.amount.description(),
      totoalBetRequest: turnover.parameters.turnoverRequest.description(),
      remainBetRequest: turnover.remainAmount.description(),
      percentage: turnover.parameters.percentage.description(),
      ratio: turnover.parameters.percentage.percent / 100)
  }
}

// MARK: - Model

extension TurnoverAlertViewModel {
  struct Detail {
    var gameName = "-"
    var receiveBonusDate = "-"
    var turnoverName = "-"
    var receiveAmount = "-"
    var totoalBetRequest = "-"
    var remainBetRequest = "-"
    var percentage = "-"
    var ratio: Double = 0
  }
}
