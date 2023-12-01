import Foundation
import sharedbu

class TransactionResourceAdapter: TransactionResource {
  override var cash: KotlinLazy { Localize.convert(resourceId: ResourceKey(key: "balancelog_cash")) }
  override var cryptoMarket: KotlinLazy { Localize.convert(resourceId: ResourceKey(key: "cps_crypto_market")) }
  override var parley: KotlinLazy { Localize.convert(resourceId: ResourceKey(key: "product_sbk_parlay")) }
  var ethereum: KotlinLazy { Localize.convert(resourceId: ResourceKey(key: "common_ethereum")) }
  
  override func bonusResourceMapper(productGroup: ProductType) -> ResourceIdEnumMapper {
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

  override func productTypeMapper() -> ResourceIdMapper {
    ProductNameMapper()
  }

  override func transactionLogMapper() -> ResourceIdMapper {
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
