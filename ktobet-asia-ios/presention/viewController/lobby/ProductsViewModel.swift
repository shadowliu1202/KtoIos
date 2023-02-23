import Foundation
import RxSwift
import SharedBu

class ProductsViewModel: CollectErrorViewModel {
  private let maintenanceSubject = PublishSubject<MaintenanceStatus>()
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
    maintenanceSubject
      .asObservable()
      .do(onSubscribe: { [weak self] in
        guard let self else { return }

        self._observeMaintenanceStatus()
      })
  }

  private func _observeMaintenanceStatus() {
    observeSystemMessageUseCase
      .observeMaintenanceStatus(useCase: self.getSystemStatusUseCase)
      .subscribe(onNext: { [weak self] maintenanceStatus in
        guard let self else { return }

        self.maintenanceSubject
          .onNext(maintenanceStatus)
      })
      .disposed(by: disposeBag)
  }

  func fetchMaintenanceStatus() {
    getSystemStatusUseCase
      .fetchMaintenanceStatus()
      .subscribe(onSuccess: { [weak self] maintenanceStatus in
        guard let self else { return }

        self.maintenanceSubject
          .onNext(maintenanceStatus)

      }, onFailure: { [weak self] error in
        guard let self else { return }

        self.errorsSubject
          .onNext(error)
      })
      .disposed(by: disposeBag)
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
