import Foundation
import SharedBu
import RxSwift

protocol TransactionLogRepository {
    func searchTransactionLog(from: Date, to: Date, BalanceLogFilterType: Int, page: Int) -> Single<[TransactionLog]>
    func getCashFlowSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<CashFlowSummary>
    func getCashLogSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<CashLogSummary>
    func getBalanceLogDetail(transactionId: String) -> Single<BalanceLogDetail>
    func getCasinoWagerDetail(wagerId: String, zoneOffset: Kotlinx_datetimeZoneOffset) -> Single<String>
    func getSportsBookWagerDetail(wagerId: String, zoneOffset: Kotlinx_datetimeZoneOffset) -> Single<String>
}

class TransactionLogRepositoryImpl: TransactionLogRepository {
    private var transactionLogApi: TransactionLogApi!
    
    init(_ transactionLogApi: TransactionLogApi) {
        self.transactionLogApi = transactionLogApi
    }
    
    func searchTransactionLog(from: Date, to: Date, BalanceLogFilterType: Int, page: Int) -> Single<[TransactionLog]> {
        let transactionFactory = TransactionFactory.init(supporter: Localize, resourceMapper: TransactionResourceFactory(), transactionString: TransactionLogFactoryTransactionString.init())
        
        return transactionLogApi.searchBalanceLogs(begin: from.toDateString(), end: to.toDateString(), balanceLogFilterType: BalanceLogFilterType, page: page).map { response -> [TransactionLog] in
            guard let data = response.data?.payload.flatMap({ balanceDateLogBean in
                return balanceDateLogBean.logs
            })  else { return [] }
            
            return data.map{ $0.toBalanceLog(transactionFactory: transactionFactory) }
        }
    }
    
    func getCashFlowSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<CashFlowSummary> {
        transactionLogApi.getIncomeOutcomeAmount(begin: begin.toDateString(), end: end.toDateString(), balanceLogFilterType: balanceLogFilterType).flatMap{ response in
            if let data = response.data {
                return Single.just(CashFlowSummary(income: CashAmount(amount: data.incomeAmount), outcome: CashAmount(amount: data.outcomeAmount)))
            } else {
                return Single.error(KTOError.EmptyData)
            }
        }
    }
    
    func getCashLogSummary(begin: Date, end: Date, balanceLogFilterType: Int) -> Single<CashLogSummary> {
        transactionLogApi.getCashLogSummary(begin: begin.toDateString(), end: end.toDateString(), balanceLogFilterType: balanceLogFilterType).flatMap { response in
            if let data = response.data {
                return Single.just(CashLogSummary(deposit: CashAmount(amount: data.depositAmount),
                                                  withdrawal: CashAmount(amount: data.withdrawalAmount),
                                                  sportsBook: CashAmount(amount: data.sportsbookAmount),
                                                  slot: CashAmount(amount: data.slotAmount),
                                                  casino: CashAmount(amount: data.casinoAmount),
                                                  numberGame: CashAmount(amount: data.numberGameAmount),
                                                  p2pAmount: CashAmount(amount: data.p2pAmount),
                                                  arcadeAmount: CashAmount(amount: data.arcadeAmount),
                                                  adjustmentAmount: CashAmount(amount: data.adjustmentAmount),
                                                  bonusAmount: CashAmount(amount: data.bonusAmount),
                                                  previousBalance: CashAmount(amount: data.previousBalance),
                                                  afterBalance: CashAmount(amount: data.afterBalance),
                                                  totalSummary: CashAmount(amount: data.totalAmount)))
            } else {
                return Single.error(KTOError.EmptyData)
            }
        }
    }
        
    func getBalanceLogDetail(transactionId: String) -> Single<BalanceLogDetail> {
        return transactionLogApi.getBalanceLogDetail(transactionId: transactionId).flatMap({[unowned self] (response) in
            let data = response.data
            let transactionType = TransactionTypes.Companion.init().create(type: data.transactionType)
            switch transactionType {
            case is TransactionTypes.Adjustment, is TransactionTypes.DepositFeeRefund:
                return self.convertToBalanceLogDetail(detail: data)
            case is TransactionTypes.Bonus:
                return self.getBonusBalanceLogDetail(detail: data)
            default:
                return self.getGeneralBalanceLogDetail(detail: data)
            }
        })
    }
    
    func getCasinoWagerDetail(wagerId: String, zoneOffset: Kotlinx_datetimeZoneOffset) -> Single<String> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return transactionLogApi.getBalanceLogCasinoWagerDetail(wagerId: wagerId, offset: secondsToHours).map{
            return $0.data ?? ""
        }
    }
    
    func getSportsBookWagerDetail(wagerId: String, zoneOffset: Kotlinx_datetimeZoneOffset) -> Single<String> {
        let secondsToHours = zoneOffset.totalSeconds / 3600
        return transactionLogApi.getBalanceLogSportsBookWagerDetail(wagerId: wagerId, offset: secondsToHours).map({
            return $0.data ?? ""
        })
    }
    
    private func convertToBalanceLogDetail(detail: BalanceLogDetailBean) -> Single<BalanceLogDetail> {
        return Single.just(detail.toBalanceLogDetail())
    }
    
    private func getBonusBalanceLogDetail(detail: BalanceLogDetailBean) -> Single<BalanceLogDetail> {
        return transactionLogApi.getBalanceLogBonusRemark(externalId: detail.wagerMappingId ?? detail.externalId).map({ (response) in
            return detail.toBalanceLogDetail(remark: response.data?.toBalanceLogDetailRemark())
        })
    }
    
    private func getGeneralBalanceLogDetail(detail: BalanceLogDetailBean) -> Single<BalanceLogDetail> {
        return transactionLogApi.getBalanceLogDetailRemark(externalId: detail.wagerMappingId ?? detail.externalId).map { (response) in
            detail.toBalanceLogDetail(remark: response.data?.toBalanceLogDetailRemark())
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
        case .p2p, .none:
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
        func map(item: Any?) -> ResourceKey {
            return ResourceKey.Companion.init().UNDEFINED
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
                return ResourceKey.Companion.init().UNDEFINED
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
                return ResourceKey.Companion.init().UNDEFINED
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
                return ResourceKey.Companion.init().UNDEFINED
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
                return ResourceKey.Companion.init().UNDEFINED
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
                return ResourceKey.Companion.init().UNDEFINED
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
                return ResourceKey.Companion.init().UNDEFINED
            default:
                return ResourceKey.Companion.init().UNDEFINED
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
                return ResourceKey.Companion.init().UNDEFINED
            case .ProductWin():
                return ResourceKey(key: "balancelog_settle")
            case .ProductLose():
                return ResourceKey.Companion.init().UNDEFINED
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
            case .ProductTipsVoid(), .ProductEventBonusVoid(), .ProductStrikeCancel(), .ProductRevise(), .Unknown():
                return ResourceKey.Companion.init().UNDEFINED
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
    var ethereum: KotlinLazy = Localize.convert(resourceId: ResourceKey(key: "common_ethereum"))
    var parley: KotlinLazy = Localize.convert(resourceId: ResourceKey(key: "product_sbk_parlay"))
}
