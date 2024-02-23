import Foundation
import sharedbu

class TransactionResourceAdapter: TransactionResource {
  override var cash: KotlinLazy { Localize.convert(resourceId: ResourceKey(key: "balancelog_cash")) }
  override var cryptoMarket: KotlinLazy { Localize.convert(resourceId: ResourceKey(key: "cps_crypto_market")) }
  override var parley: KotlinLazy { Localize.convert(resourceId: ResourceKey(key: "product_sbk_parlay")) }
  var ethereum: KotlinLazy { Localize.convert(resourceId: ResourceKey(key: "common_ethereum")) }
  
  override func bonusResourceMapper(productGroup: ProductType) -> ResourceIdEnumMapper {
    switch productGroup {
    case .numberGame:
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
         .p2P:
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
      case .depositBonus,
           .freeBet,
           .levelBonus,
           .other,
           .vvipcashback:
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
      case .depositBonus,
           .freeBet,
           .levelBonus,
           .other,
           .vvipcashback:
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
      case .depositBonus,
           .freeBet,
           .levelBonus,
           .other,
           .product,
           .vvipcashback:
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
      case .depositBonus,
           .freeBet,
           .levelBonus,
           .other,
           .product,
           .vvipcashback:
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
      case .depositBonus,
           .freeBet,
           .levelBonus,
           .other,
           .product,
           .vvipcashback:
        return ResourceKey.Companion().UNDEFINED
      }
    }
  }

  class ProductNameMapper: ResourceIdMapper {
    func map(item: Any?) -> ResourceKey {
      guard let type = item as? ProductGroup else {
        return ResourceKey(key: "")
      }

      switch onEnum(of: type.self) {
      case .arcade:
        return ResourceKey(key: "common_arcade")
      case .casino:
        return ResourceKey(key: "common_casino")
      case .numberGame:
        return ResourceKey(key: "common_keno")
      case .p2P:
        return ResourceKey(key: "common_p2p")
      case .slot:
        return ResourceKey(key: "common_slot")
      case .sportsBook:
        return ResourceKey(key: "common_sportsbook")
      case .unSupport:
        return ResourceKey.Companion().UNDEFINED
      }
    }
  }

  class TransactionResourceMapper: ResourceIdMapper {
    func map(item: Any?) -> ResourceKey {
      guard let type = item as? TransactionTypes else {
        return ResourceKey(key: "")
      }
      
      switch onEnum(of: type) {
      case .adjustment:
        return ResourceKey(key: "common_adjustment")
      case .bonus:
        return ResourceKey(key: "common_bonus")
      case .depositFeeRefund:
        return ResourceKey(key: "balancelog_deposit_refund")
      case .moneyTransfer(let it):
        switch onEnum(of: it) {
        case .a2PTransferIn:
          return ResourceKey(key: "balancelog_deposit_a2p_in")
        case .deposit:
          return ResourceKey(key: "common_deposit")
        case .p2ATransferOut:
          return ResourceKey(key: "balancelog_withdrawal_p2a_out")
        case .p2PTransferIn:
          return ResourceKey(key: "balancelog_deposit_p2p_in")
        case .p2PTransferOut:
          return ResourceKey(key: "balancelog_withdrawal_p2p_out")
        case .withdrawal:
          return ResourceKey(key: "common_withdrawal")
        }
      case .product(let it):
        switch onEnum(of: it) {
        case .bet:
          return ResourceKey(key: "common_bet")
        case .cancel:
          return ResourceKey(key: "common_cancel")
        case .eventBonus:
          return ResourceKey(key: "balancelog_eventbonus")
        case .lose:
          return ResourceKey.Companion().UNDEFINED
        case .playerCancel:
          return ResourceKey(key: "balancelog_player_cancel")
        case .push:
          return ResourceKey.Companion().UNDEFINED
        case .tips:
          return ResourceKey(key: "balancelog_eventbonus")
        case .unSettle:
          return ResourceKey(key: "balancelog_unsettled")
        case .void:
          return ResourceKey(key: "common_reject")
        case .win:
          return ResourceKey(key: "balancelog_settle")
        case .enterTable,
             .eventBonusVoid,
             .leaveTable,
             .revise,
             .strikeCancel,
             .tipsVoid:
          return ResourceKey.Companion().UNDEFINED
        }
      case .unknown:
        return ResourceKey(key: "")
      }
    }
  }
}
