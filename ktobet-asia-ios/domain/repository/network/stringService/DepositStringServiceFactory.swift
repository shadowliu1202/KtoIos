import Foundation
import SharedBu

class DepositStringServiceFactory: ExternalStringService {
    func deposit() -> DepositStringService {
        depositStringService(cpsCryptoCurrencyDepositHint: ResourceKey(key: Localize.string("cps_crypto_currency_deposit_hint")),
                             depositCpsHint: KNLazyCompanion().create(input: Localize.string("deposit_cps_hint")),
                             depositFloatAmountHelpSpeed: KNLazyCompanion().create(input: Localize.string("deposit_float_hint")),
                             depositMultipleHint: KNLazyCompanion().create(input: Localize.string("deposit_pay_multiple_hint")),
                             depositAmountOptionHint: KNLazyCompanion().create(input: Localize.string("deposit_amount_option_hint")),
                             cpsCryptoCurrencyDepositFeeMaximumHint: ResourceKey(key: Localize.string("cps_crypto_currency_deposit_hint")),
                             cpsCryptoCurrencyDepositFeeTimesHint: ResourceKey(key: Localize.string("cps_crypto_currency_deposit_times_hint")),
                             cryptoMarketPromotionFeeMaximumHint: ResourceKey(key: Localize.string("cps_deposit_market_condition_amount_per_day")),
                             cryptoMarketPromotionFeeTimesHint: ResourceKey(key: Localize.string("cps_deposit_market_condition_times_per_day")))
    }
}

class depositStringService: DepositStringService {
    var cpsCryptoCurrencyDepositFeeMaximumHint: ResourceKey
    var cpsCryptoCurrencyDepositFeeTimesHint: ResourceKey
    var cpsCryptoCurrencyDepositHint: ResourceKey
    var cryptoMarketPromotionFeeMaximumHint: ResourceKey
    var cryptoMarketPromotionFeeTimesHint: ResourceKey
    var depositCpsHint: KotlinLazy
    var depositFloatAmountHelpSpeed: KotlinLazy
    var depositMultipleHint: KotlinLazy
    var depositAmountOptionHint: KotlinLazy
    
    init(cpsCryptoCurrencyDepositHint: ResourceKey,
         depositCpsHint: KotlinLazy,
         depositFloatAmountHelpSpeed: KotlinLazy,
         depositMultipleHint: KotlinLazy,
         depositAmountOptionHint: KotlinLazy,
         cpsCryptoCurrencyDepositFeeMaximumHint: ResourceKey,
         cpsCryptoCurrencyDepositFeeTimesHint: ResourceKey,
         cryptoMarketPromotionFeeMaximumHint: ResourceKey,
         cryptoMarketPromotionFeeTimesHint: ResourceKey) {
        self.cpsCryptoCurrencyDepositHint = cpsCryptoCurrencyDepositHint
        self.depositCpsHint = depositCpsHint
        self.depositFloatAmountHelpSpeed = depositFloatAmountHelpSpeed
        self.depositMultipleHint = depositMultipleHint
        self.depositAmountOptionHint = depositAmountOptionHint
        self.cpsCryptoCurrencyDepositFeeMaximumHint = cpsCryptoCurrencyDepositFeeMaximumHint
        self.cpsCryptoCurrencyDepositFeeTimesHint = cpsCryptoCurrencyDepositFeeTimesHint
        self.cryptoMarketPromotionFeeMaximumHint = cryptoMarketPromotionFeeMaximumHint
        self.cryptoMarketPromotionFeeTimesHint = cryptoMarketPromotionFeeTimesHint
    }
}
