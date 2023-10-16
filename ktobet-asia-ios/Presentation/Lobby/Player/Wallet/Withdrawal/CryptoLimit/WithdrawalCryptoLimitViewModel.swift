import RxSwift
import sharedbu
import SwiftUI

class WithdrawalCryptoLimitViewModel:
  WithdrawalCryptoLimitViewModelProtocol &
  ObservableObject &
  CollectErrorViewModel
{
  @Published var remainRequirement: String?
  @Published var summaryRequirement: WithdrawalCryptoLimitDataModel.Summary?
  @Published var summaryAchieved: WithdrawalCryptoLimitDataModel.Summary?

  private let withdrawalAppService: IWithdrawalAppService
  private let playerConfiguration: PlayerConfiguration

  private let disposeBag = DisposeBag()

  init(
    _ withdrawalAppService: IWithdrawalAppService,
    _ playerConfiguration: PlayerConfiguration)
  {
    self.withdrawalAppService = withdrawalAppService
    self.playerConfiguration = playerConfiguration
  }

  func setupData() {
    Single.from(
      withdrawalAppService
        .getCryptoTurnOverSummary())
      .observe(on: MainScheduler.instance)
      .subscribe(
        onSuccess: { [weak self] DTO in
          self?.remainRequirement = DTO.remain.denomination()

          self?.summaryRequirement = self?.parseToSummary(
            totalAmount: DTO.request,
            records: DTO.requestLogs,
            isWithdrawal: false)

          self?.summaryAchieved = self?.parseToSummary(
            totalAmount: DTO.achieved,
            records: DTO.achievedLogs,
            isWithdrawal: true)
        },
        onFailure: { [weak self] error in
          self?.errorsSubject
            .onNext(error)
        })
      .disposed(by: disposeBag)
  }

  private func parseToSummary(
    totalAmount: CurrencyUnit,
    records DTOs: [TurnOverLog],
    isWithdrawal: Bool)
    -> WithdrawalCryptoLimitDataModel.Summary
  {
    .init(
      title: getTitle(amount: totalAmount, isWithdrawal),
      records: DTOs.map {
        .init(
          id: $0.displayId,
          dateTime: $0.approvedDate.toDateTimeString(),
          fiatAmount: getSign(isWithdrawal) + $0.fiatAmount.denomination(),
          cryptoAmount: $0.cryptoAmount.denomination())
      })
  }

  private func getTitle(
    amount: CurrencyUnit,
    _ isWithdrawal: Bool)
    -> String
  {
    isWithdrawal
      ? Localize.string("cps_total_completed_amount", amount.denomination())
      : Localize.string("cps_total_require_amount", amount.denomination())
  }

  private func getSign(_ isWithdrawal: Bool) -> String {
    isWithdrawal ? "-" : "+"
  }

  func getSupportLocale() -> SupportLocale {
    playerConfiguration.supportLocale
  }
}
