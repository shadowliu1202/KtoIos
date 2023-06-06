import Foundation
import SharedBu

class DepositStringServiceAdapter: DepositStringService {
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
