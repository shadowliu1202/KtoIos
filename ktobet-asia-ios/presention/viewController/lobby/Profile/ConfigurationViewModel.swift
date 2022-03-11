import RxSwift
import RxCocoa
import SharedBu

class ConfigurationViewModel {
    private var configurationUseCase : ConfigurationUseCase!
    
    init(_ configurationUseCase : ConfigurationUseCase) {
        self.configurationUseCase = configurationUseCase
    }
    
    func fetchDefaultProduct() -> Single<ProductType> {
        return configurationUseCase.defaultProduct()
    }
    
    func saveDefaultProduct(productType: ProductType) -> Completable {
        return configurationUseCase.saveDefaultProduct(productType)
    }
}
