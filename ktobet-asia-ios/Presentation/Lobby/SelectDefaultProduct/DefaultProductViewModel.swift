import RxCocoa
import RxSwift
import SharedBu
import UIKit

class DefaultProductViewModel {
  private var disposeBag = DisposeBag()
  private var usecaseConfig: ConfigurationUseCase!
  private let systemStatusUseCase: ISystemStatusUseCase!

  init(_ usecaseConfig: ConfigurationUseCase, _ systemStatusUseCase: ISystemStatusUseCase) {
    self.usecaseConfig = usecaseConfig
    self.systemStatusUseCase = systemStatusUseCase
  }

  func saveDefaultProduct(_ type: ProductType) -> Completable {
    usecaseConfig.saveDefaultProduct(type)
  }

  func getPlayerInfo() -> Single<Player> {
    usecaseConfig.getPlayerInfo()
  }

  func getPortalMaintenanceState() -> Single<MaintenanceStatus> {
    systemStatusUseCase.fetchMaintenanceStatus()
  }
}
