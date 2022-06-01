import Foundation
import SharedBu

class DepositStringServiceFactory: ExternalStringService {
    func deposit() -> DepositStringService {
        depositStringService(cpsCryptoCurrencyDepositHint: ResourceKey(key: Localize.string("cps_crypto_currency_deposit_hint")),
                             depositCpsHint: KNLazyCompanion().create(input: Localize.string("deposit_cps_hint")), depositFloatAmountHelpSpeed: KNLazyCompanion().create(input: Localize.string("deposit_float_hint")),
                             depositMultipleHint: KNLazyCompanion().create(input: Localize.string("deposit_pay_multiple_hint")),
                             cpsCryptoCurrencyDepositFeeMaximumHint: ResourceKey(key: Localize.string("cps_crypto_currency_deposit_hint")),
                             cpsCryptoCurrencyDepositFeeTimesHint: ResourceKey(key: Localize.string("cps_crypto_currency_deposit_times_hint")))
    }
}

class depositStringService: DepositStringService {
    var cpsCryptoCurrencyDepositFeeMaximumHint: ResourceKey
    var cpsCryptoCurrencyDepositFeeTimesHint: ResourceKey
    var cpsCryptoCurrencyDepositHint: ResourceKey
    var depositCpsHint: KotlinLazy
    var depositFloatAmountHelpSpeed: KotlinLazy
    var depositMultipleHint: KotlinLazy
    
    init(cpsCryptoCurrencyDepositHint: ResourceKey,
         depositCpsHint: KotlinLazy,
         depositFloatAmountHelpSpeed: KotlinLazy,
         depositMultipleHint: KotlinLazy,
         cpsCryptoCurrencyDepositFeeMaximumHint: ResourceKey,
         cpsCryptoCurrencyDepositFeeTimesHint: ResourceKey) {
        self.cpsCryptoCurrencyDepositHint = cpsCryptoCurrencyDepositHint
        self.depositCpsHint = depositCpsHint
        self.depositFloatAmountHelpSpeed = depositFloatAmountHelpSpeed
        self.depositMultipleHint = depositMultipleHint
        self.cpsCryptoCurrencyDepositFeeMaximumHint = cpsCryptoCurrencyDepositFeeMaximumHint
        self.cpsCryptoCurrencyDepositFeeTimesHint = cpsCryptoCurrencyDepositFeeTimesHint
    }
}
