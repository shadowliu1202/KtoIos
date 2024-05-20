import Foundation
import sharedbu

class DepositStringServiceAdapter: DepositStringService {
    let cpsCryptoCurrencyDepositFeeMaximumHint = ResourceKey(key: Localize.string("cps_crypto_currency_deposit_hint"))
    let cpsCryptoCurrencyDepositFeeTimesHint = ResourceKey(key: Localize.string("cps_crypto_currency_deposit_times_hint"))
    let cryptoMarketPromotionFeeMaximumHint = ResourceKey(key: Localize.string("cps_deposit_market_condition_amount_per_day"))
    let cryptoMarketPromotionFeeTimesHint = ResourceKey(key: Localize.string("cps_deposit_market_condition_times_per_day"))
    let depositCpsHint: KotlinLazy = KNLazyCompanion().create(input: Localize.string("deposit_cps_hint"))
    let depositMultipleHint: KotlinLazy = KNLazyCompanion().create(input: Localize.string("deposit_pay_multiple_hint"))
    let jingDongRequiredHint: KotlinLazy = KNLazyCompanion().create(input: Localize.string("deposit_download_jingdong_app"))
}
