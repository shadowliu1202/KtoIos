import Foundation
import SharedBu

class ExternalStringServiceFactory: ExternalStringService {
  func deposit() -> DepositStringService {
    DepositStringServiceAdapter(
      cpsCryptoCurrencyDepositFeeMaximumHint: ResourceKey(key: Localize.string("cps_crypto_currency_deposit_hint")),
      cpsCryptoCurrencyDepositFeeTimesHint: ResourceKey(key: Localize.string("cps_crypto_currency_deposit_times_hint")),
      cryptoMarketPromotionFeeMaximumHint: ResourceKey(key: Localize.string("cps_deposit_market_condition_amount_per_day")),
      cryptoMarketPromotionFeeTimesHint: ResourceKey(key: Localize.string("cps_deposit_market_condition_times_per_day")),
      depositCpsHint: KNLazyCompanion().create(input: Localize.string("deposit_cps_hint")),
      depositMultipleHint: KNLazyCompanion().create(input: Localize.string("deposit_pay_multiple_hint")),
      jingDongRequiredHint: KNLazyCompanion().create(input: Localize.string("deposit_download_jingdong_app")))
  }
}
