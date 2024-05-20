import RxCocoa
import RxSwift
import sharedbu
import UIKit

class DefaultProductViewModel {
    private let useCaseConfig: ConfigurationUseCase
    private let systemStatusUseCase: ISystemStatusUseCase
    private let appService: DefaultProductAppService

    private let disposeBag = DisposeBag()

    init(
        _ useCaseConfig: ConfigurationUseCase,
        _ systemStatusUseCase: ISystemStatusUseCase,
        _ appService: DefaultProductAppService)
    {
        self.useCaseConfig = useCaseConfig
        self.systemStatusUseCase = systemStatusUseCase
        self.appService = appService
    }
  
    func setDefaultProduct(_ type: DefaultProductType) -> Completable {
        Completable.from(appService.setDefaultProduct(type: type))
    }

    func getPortalMaintenanceState() -> Single<MaintenanceStatus> {
        systemStatusUseCase.fetchMaintenanceStatus()
    }
}
