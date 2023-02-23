import Foundation
import SharedBu

class DepositStringServiceFactory: ExternalStringService {
  func deposit() -> DepositStringService {
    depositStringService(
      cpsCryptoCurrencyDepositFeeMaximumHint: ResourceKey(key: Localize.string("cps_crypto_currency_deposit_hint")),
      cpsCryptoCurrencyDepositFeeTimesHint: ResourceKey(key: Localize.string("cps_crypto_currency_deposit_times_hint")),
      cryptoMarketPromotionFeeMaximumHint: ResourceKey(key: Localize.string("cps_deposit_market_condition_amount_per_day")),
      cryptoMarketPromotionFeeTimesHint: ResourceKey(key: Localize.string("cps_deposit_market_condition_times_per_day")),
      depositCpsHint: KNLazyCompanion().create(input: Localize.string("deposit_cps_hint")),
      depositMultipleHint: KNLazyCompanion().create(input: Localize.string("deposit_pay_multiple_hint")),
      jingDongRequiredHint: KNLazyCompanion().create(input: Localize.string("deposit_download_jingdong_app")))
  }
}

class depositStringService: DepositStringService {
  var cpsCryptoCurrencyDepositFeeMaximumHint: ResourceKey
  var cpsCryptoCurrencyDepositFeeTimesHint: ResourceKey
  var cryptoMarketPromotionFeeMaximumHint: ResourceKey
  var cryptoMarketPromotionFeeTimesHint: ResourceKey
  var depositCpsHint: KotlinLazy
  var depositMultipleHint: KotlinLazy
  var jingDongRequiredHint: KotlinLazy

  init(
    cpsCryptoCurrencyDepositFeeMaximumHint: ResourceKey,
    cpsCryptoCurrencyDepositFeeTimesHint: ResourceKey,
    cryptoMarketPromotionFeeMaximumHint: ResourceKey,
    cryptoMarketPromotionFeeTimesHint: ResourceKey,
    depositCpsHint: KotlinLazy,
    depositMultipleHint: KotlinLazy,
    jingDongRequiredHint: KotlinLazy)
  {
    self.cpsCryptoCurrencyDepositFeeMaximumHint = cpsCryptoCurrencyDepositFeeMaximumHint
    self.cpsCryptoCurrencyDepositFeeTimesHint = cpsCryptoCurrencyDepositFeeTimesHint
    self.cryptoMarketPromotionFeeMaximumHint = cryptoMarketPromotionFeeMaximumHint
    self.cryptoMarketPromotionFeeTimesHint = cryptoMarketPromotionFeeTimesHint
    self.depositCpsHint = depositCpsHint
    self.depositMultipleHint = depositMultipleHint
    self.jingDongRequiredHint = jingDongRequiredHint
  }
}
