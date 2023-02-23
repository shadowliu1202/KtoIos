import Foundation
import RxSwift
import SharedBu

class SportBookViewModel: CollectErrorViewModel {
  private let disposeBag = DisposeBag()

  private let observeSystemMessageUseCase: ObserveSystemMessageUseCase
  private let getSystemStatusUseCase: GetSystemStatusUseCase

  init(
    observeSystemMessageUseCase: ObserveSystemMessageUseCase,
    getSystemStatusUseCase: GetSystemStatusUseCase)
  {
    self.observeSystemMessageUseCase = observeSystemMessageUseCase
    self.getSystemStatusUseCase = getSystemStatusUseCase
  }

  func observeMaintenanceStatus() -> Observable<MaintenanceStatus> {
    observeSystemMessageUseCase
      .observeMaintenanceStatus(useCase: self.getSystemStatusUseCase)
  }

  override func errors() -> Observable<Error> {
    errorsSubject
      .do(onSubscribe: { [weak self] in
        guard let self else { return }

        self.observeSystemMessageUseCase.errors()
          .subscribe(onNext: { [weak self] error in
            guard let self else { return }

            self.errorsSubject
              .onNext(error)
          })
          .disposed(by: self.disposeBag)
      })
      .throttle(.milliseconds(1500), latest: false, scheduler: MainScheduler.instance)
  }
}
