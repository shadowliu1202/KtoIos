import Foundation
import RxSwift
import sharedbu
import SwiftUI

class WithdrawalMainViewModel:
  CollectErrorViewModel,
  WithdrawalMainViewModelProtocol,
  ObservableObject
{
  @Published private(set) var instruction: WithdrawalMainViewDataModel.Instruction?
  @Published private(set) var methods: [WithdrawalDto.Method] = []
  @Published private(set) var recentRecords: [WithdrawalMainViewDataModel.Record]?

  @Published private(set) var enableWithdrawal = false
  @Published private(set) var allowedWithdrawalFiat: Bool?
  @Published private(set) var allowedWithdrawalCrypto: Bool?

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
    getInstruction()
    getMethods()
    getRecords()
  }

  private func getInstruction() {
    Single.from(
      withdrawalAppService
        .getWithdrawalInstruction())
      .observe(on: MainScheduler.instance)
      .subscribe(
        onSuccess: { [weak self] instructionDTO in
          guard let self else { return }

          self.instruction = .init(
            dailyAmountLimit: instructionDTO.dailyLimitation.maxAmount.description(),
            dailyMaxCount: "\(instructionDTO.dailyLimitation.maxCount)",
            turnoverRequirement: self.getTurnoverRequirement(instructionDTO),
            cryptoWithdrawalRequirement: self.getCryptoWithdrawalRequirement(instructionDTO))

          self.enableWithdrawal = instructionDTO.hasWithdrawalBudget

          self.allowedWithdrawalFiat = instructionDTO.incompleteCryptoTurnOver?.isPositive == true
            ? false
            : true

          self.allowedWithdrawalCrypto = instructionDTO.isCryptoProcessCertified
        },
        onFailure: { [weak self] error in
          self?.errorsSubject
            .onNext(error)
        })
      .disposed(by: disposeBag)
  }
  
  private func getMethods() {
    Single.from(withdrawalAppService.getMethods())
      .map { $0 as! [WithdrawalDto.Method] }
      .observe(on: MainScheduler.instance)
      .subscribe(
        onSuccess: { [unowned self] in methods = $0 },
        onFailure: { [unowned self] in errorsSubject.onNext($0) })
      .disposed(by: disposeBag)
  }

  private func getTurnoverRequirement(_ instructionDTO: WithdrawalDto.Instruction) -> String? {
    if
      let amount = instructionDTO.incompleteBetTurnOver,
      amount.isPositive
    {
      return amount.description()
    }
    else {
      return nil
    }
  }

  private func getCryptoWithdrawalRequirement(_ instructionDTO: WithdrawalDto.Instruction) -> (String, String)? {
    if
      let amount = instructionDTO.incompleteCryptoTurnOver,
      amount.isPositive
    {
      return (amount.description(), amount.simpleName)
    }
    else {
      return nil
    }
  }

  private func getRecords() {
    Single.from(
      withdrawalAppService
        .getRecentLogs())
      .observe(on: MainScheduler.instance)
      .subscribe(
        onSuccess: { [weak self] nsArray in
          guard let self else { return }

          let logs = nsArray as! [WithdrawalDto.Log]

          self.recentRecords = logs
            .map { logDTO in
              WithdrawalMainViewDataModel.Record(
                id: logDTO.displayId,
                currencyType: logDTO.type,
                date: logDTO.createdDate.toDateTimeString(),
                status: self.parseLogStatus(logDTO),
                amount: logDTO.amount.description())
            }
        },
        onFailure: { [weak self] error in
          self?.errorsSubject
            .onNext(error)
        })
      .disposed(by: disposeBag)
  }

  private func parseLogStatus(_ log: WithdrawalDto.Log) -> WithdrawalMainViewDataModel.TransactionStatus {
    .init(title: log.status.toString(), color: log.status.toColor())
  }

  func getSupportLocale() -> SupportLocale {
    playerConfiguration.supportLocale
  }
}
