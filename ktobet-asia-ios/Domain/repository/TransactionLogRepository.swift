import Foundation
import RxSwift
import sharedbu

protocol TransactionLogRepository {
  func searchTransactionLog(from: Date, to: Date, BalanceLogFilterType: Int, page: Int) -> Single<[TransactionLog]>
  func getCashFlowSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<CashFlowSummary>
  func getCashLogSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<CashLogSummary>
  func getBalanceLogDetail(transactionId: String) -> Single<BalanceLogDetail>
  func getCasinoWagerDetail(wagerId: String, zoneOffset: sharedbu.UtcOffset) -> Single<String>
  func getSportsBookWagerDetail(wagerId: String, zoneOffset: sharedbu.UtcOffset) -> Single<String>
}

class TransactionLogRepositoryImpl: TransactionLogRepository {
  private var transactionLogApi: TransactionLogApi!

  init(_ transactionLogApi: TransactionLogApi) {
    self.transactionLogApi = transactionLogApi
  }

  func searchTransactionLog(from: Date, to: Date, BalanceLogFilterType: Int, page: Int) -> Single<[TransactionLog]> {
    let transactionFactory = TransactionFactory(
      supporter: Localize,
      resourceMapper: TransactionResourceFactory(),
      transactionString: TransactionLogFactoryTransactionString())

    return transactionLogApi.searchBalanceLogs(
      begin: from.toDateString(),
      end: to.toDateString(),
      balanceLogFilterType: BalanceLogFilterType,
      page: page).map { response -> [TransactionLog] in
      guard
        let data = response.data?.payload.flatMap({ balanceDateLogBean in
          balanceDateLogBean.logs
        }) else { return [] }

      return try data.map { try $0.toBalanceLog(transactionFactory: transactionFactory) }
    }
  }

  func getCashFlowSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<CashFlowSummary> {
    transactionLogApi.getIncomeOutcomeAmount(
      begin: begin.toDateString(),
      end: end.toDateString(),
      balanceLogFilterType: balanceLogFilterType).flatMap { response in
      if let data = response.data {
        return Single
          .just(CashFlowSummary(
            income: data.incomeAmount.toAccountCurrency(),
            outcome: data.outcomeAmount.toAccountCurrency()))
      }
      else {
        return Single.error(KTOError.EmptyData)
      }
    }
  }

  func getCashLogSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<CashLogSummary> {
    transactionLogApi.getCashLogSummary(
      begin: begin.toDateString(),
      end: end.toDateString(),
      balanceLogFilterType: balanceLogFilterType).flatMap { response in
      if let data = response.data {
        return Single.just(CashLogSummary(
          deposit: data.depositAmount.toAccountCurrency(),
          withdrawal: data.withdrawalAmount.toAccountCurrency(),
          sportsBook: data.sportsbookAmount.toAccountCurrency(),
          slot: data.slotAmount.toAccountCurrency(),
          casino: data.casinoAmount.toAccountCurrency(),
          numberGame: data.numberGameAmount.toAccountCurrency(),
          p2pAmount: data.p2pAmount.toAccountCurrency(),
          arcadeAmount: data.arcadeAmount.toAccountCurrency(),
          adjustmentAmount: data.adjustmentAmount.toAccountCurrency(),
          bonusAmount: data.bonusAmount.toAccountCurrency(),
          previousBalance: data.previousBalance.toAccountCurrency(),
          afterBalance: data.afterBalance.toAccountCurrency(),
          totalSummary: data.totalAmount.toAccountCurrency()))
      }
      else {
        return Single.error(KTOError.EmptyData)
      }
    }
  }

  func getBalanceLogDetail(transactionId: String) -> Single<BalanceLogDetail> {
    transactionLogApi.getBalanceLogDetail(transactionId: transactionId).flatMap({ [unowned self] response in
      let data = response.data
      let transactionType = TransactionTypes.Companion().create(type: data.transactionType)
      switch transactionType {
      case is TransactionTypes.Adjustment,
           is TransactionTypes.DepositFeeRefund:
        return try convertToBalanceLogDetail(detail: data)
      case is TransactionTypes.ProductEnterTable,
           is TransactionTypes.ProductLeaveTable:
        return getGeneralBalanceLogDetail(detail: data, isTransferWallet: true)
      case is TransactionTypes.Bonus:
        return getBonusBalanceLogDetail(detail: data)
      default:
        return getGeneralBalanceLogDetail(detail: data, isTransferWallet: false)
      }
    })
  }

  func getCasinoWagerDetail(wagerId: String, zoneOffset: sharedbu.UtcOffset) -> Single<String> {
    let secondsToHours = zoneOffset.totalSeconds / 3600
    return transactionLogApi.getBalanceLogCasinoWagerDetail(wagerId: wagerId, offset: secondsToHours).map {
      $0.data ?? ""
    }
  }

  func getSportsBookWagerDetail(wagerId: String, zoneOffset: sharedbu.UtcOffset) -> Single<String> {
    let secondsToHours = zoneOffset.totalSeconds / 3600
    return transactionLogApi.getBalanceLogSportsBookWagerDetail(wagerId: wagerId, offset: secondsToHours).map({
      $0.data ?? ""
    })
  }

  private func convertToBalanceLogDetail(detail: BalanceLogDetailBean) throws -> Single<BalanceLogDetail> {
    try Single.just(detail.toBalanceLogDetail())
  }

  private func getBonusBalanceLogDetail(detail: BalanceLogDetailBean) -> Single<BalanceLogDetail> {
    transactionLogApi.getBalanceLogBonusRemark(externalId: detail.wagerMappingId ?? detail.externalId).map({ response in
      try detail.toBalanceLogDetail(remark: response.data?.toBalanceLogDetailRemark())
    })
  }

  private func getGeneralBalanceLogDetail(detail: BalanceLogDetailBean, isTransferWallet: Bool) -> Single<BalanceLogDetail> {
    transactionLogApi.getBalanceLogDetailRemark(externalId: detail.wagerMappingId ?? detail.externalId).map { response in
      try detail.toBalanceLogDetail(remark: response.data?.toBalanceLogDetailRemark(isTransferWallet: isTransferWallet))
    }
  }
}

class TransactionResourceFactory: ITransactionResource {
  func bonusResourceMapper(productGroup: ProductType) -> ResourceIdEnumMapper {
    switch productGroup {
    case .numbergame:
      return NumberBonusMapper()
    case .slot:
      return SlotBonusMapper()
    case .casino:
      return CasinoBonusMapper()
    case .sbk:
      return SBKBonusMapper()
    case .arcade:
      return ArcadeBonusMapper()
    case .none,
         .p2p:
      return UNDEFINEDBonusMapper()
    default:
      return UNDEFINEDBonusMapper()
    }
  }

  func productTypeMapper() -> ResourceIdMapper {
    ProductNameMapper()
  }

  func transactionLogMapper() -> ResourceIdMapper {
    TransactionResourceMapper()
  }

  private class UNDEFINEDBonusMapper: ResourceIdEnumMapper {
    func map(item _: Any?) -> ResourceKey {
      ResourceKey.Companion().UNDEFINED
    }
  }

  private class SBKBonusMapper: ResourceIdEnumMapper {
    func map(item: Any?) -> ResourceKey {
      guard let type = item as? BonusType else {
        return ResourceKey(key: "")
      }

      switch type {
      case .product:
        return ResourceKey(key: "balancelog_producttype_1_bonustype_3")
      case .rebate:
        return ResourceKey(key: "balancelog_producttype_1_bonustype_4")
      default:
        return ResourceKey.Companion().UNDEFINED
      }
    }
  }

  private class SlotBonusMapper: ResourceIdEnumMapper {
    func map(item: Any?) -> ResourceKey {
      guard let type = item as? BonusType else {
        return ResourceKey(key: "")
      }

      switch type {
      case .product:
        return ResourceKey(key: "balancelog_producttype_2_bonustype_3")
      case .rebate:
        return ResourceKey(key: "balancelog_producttype_2_bonustype_4")
      default:
        return ResourceKey.Companion().UNDEFINED
      }
    }
  }

  private class CasinoBonusMapper: ResourceIdEnumMapper {
    func map(item: Any?) -> ResourceKey {
      guard let type = item as? BonusType else {
        return ResourceKey(key: "")
      }

      switch type {
      case .rebate:
        return ResourceKey(key: "balancelog_producttype_3_bonustype_4")
      default:
        return ResourceKey.Companion().UNDEFINED
      }
    }
  }

  private class NumberBonusMapper: ResourceIdEnumMapper {
    func map(item: Any?) -> ResourceKey {
      guard let type = item as? BonusType else {
        return ResourceKey(key: "")
      }

      switch type {
      case .rebate:
        return ResourceKey(key: "balancelog_producttype_4_bonustype_4")
      default:
        return ResourceKey.Companion().UNDEFINED
      }
    }
  }

  private class ArcadeBonusMapper: ResourceIdEnumMapper {
    func map(item: Any?) -> ResourceKey {
      guard let type = item as? BonusType else {
        return ResourceKey(key: "")
      }

      switch type {
      case .rebate:
        return ResourceKey(key: "balancelog_producttype_6_bonustype_4")
      default:
        return ResourceKey.Companion().UNDEFINED
      }
    }
  }

  class ProductNameMapper: ResourceIdMapper {
    func map(item: Any?) -> ResourceKey {
      guard let type = item as? ProductGroup else {
        return ResourceKey(key: "")
      }

      switch type.self {
      case is ProductGroup.NumberGame:
        return ResourceKey(key: "common_keno")
      case is ProductGroup.Slot:
        return ResourceKey(key: "common_slot")
      case is ProductGroup.Casino:
        return ResourceKey(key: "common_casino")
      case is ProductGroup.P2P:
        return ResourceKey(key: "common_p2p")
      case is ProductGroup.Arcade:
        return ResourceKey(key: "common_arcade")
      case is ProductGroup.SportsBook:
        return ResourceKey(key: "common_sportsbook")
      case is ProductGroup.UnSupport:
        return ResourceKey.Companion().UNDEFINED
      default:
        return ResourceKey.Companion().UNDEFINED
      }
    }
  }

  class TransactionResourceMapper: ResourceIdMapper {
    func map(item: Any?) -> ResourceKey {
      guard let type = item as? TransactionTypes else {
        return ResourceKey(key: "")
      }

      switch type {
      case .MoneyTransferDeposit():
        return ResourceKey(key: "common_deposit")
      case .MoneyTransferWithdrawal():
        return ResourceKey(key: "common_withdrawal")
      case .MoneyTransferA2PTransferIn():
        return ResourceKey(key: "balancelog_deposit_a2p_in")
      case .MoneyTransferP2ATransferOut():
        return ResourceKey(key: "balancelog_withdrawal_p2a_out")
      case .MoneyTransferP2PTransferIn():
        return ResourceKey(key: "balancelog_deposit_p2p_in")
      case .MoneyTransferP2PTransferOut():
        return ResourceKey(key: "balancelog_withdrawal_p2p_out")
      case .ProductBet():
        return ResourceKey(key: "common_bet")
      case .ProductPush():
        return ResourceKey.Companion().UNDEFINED
      case .ProductWin():
        return ResourceKey(key: "balancelog_settle")
      case .ProductLose():
        return ResourceKey.Companion().UNDEFINED
      case .ProductVoid():
        return ResourceKey(key: "common_reject")
      case .ProductPlayerCancel():
        return ResourceKey(key: "balancelog_player_cancel")
      case .ProductUnSettle():
        return ResourceKey(key: "balancelog_unsettled")
      case .ProductCancel():
        return ResourceKey(key: "common_cancel")
      case .ProductTips():
        return ResourceKey(key: "balancelog_eventbonus")
      case .ProductEventBonus():
        return ResourceKey(key: "balancelog_eventbonus")
      case .ProductEventBonusVoid(),
           .ProductRevise(),
           .ProductStrikeCancel(),
           .ProductTipsVoid(),
           .Unknown():
        return ResourceKey.Companion().UNDEFINED
      case .Adjustment():
        return ResourceKey(key: "common_adjustment")
      case .Bonus():
        return ResourceKey(key: "common_bonus")
      case .DepositFeeRefund():
        return ResourceKey(key: "balancelog_deposit_refund")
      default:
        return ResourceKey(key: "")
      }
    }
  }
}

class TransactionLogFactoryTransactionString: TransactionFactoryTransactionString {
  var cash: KotlinLazy = Localize.convert(resourceId: ResourceKey(key: "balancelog_cash"))
  var cryptoMarket: KotlinLazy = Localize.convert(resourceId: ResourceKey(key: "cps_crypto_market"))
  var ethereum: KotlinLazy = Localize.convert(resourceId: ResourceKey(key: "common_ethereum"))
  var parley: KotlinLazy = Localize.convert(resourceId: ResourceKey(key: "product_sbk_parlay"))
}
