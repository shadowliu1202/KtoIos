import Foundation
import RxSwift
import SharedBu

enum LoginStatusDTO {
  case kickout(type: KickOutSignal)
  case fetch(isLogin: Bool)
}

protocol ObserveSystemMessageUseCase {
  func observeMaintenanceStatus(useCase: GetSystemStatusUseCase) -> Observable<MaintenanceStatus>
  func observeLoginStatus(useCase: AuthenticationUseCase) -> Observable<LoginStatusDTO>
  func observePlayerBalance(useCase: PlayerDataUseCase) -> Observable<AccountCurrency>
  func errors() -> Observable<Error>
}

class ObserveSystemMessageUseCaseImpl: ObserveSystemMessageUseCase {
  private let maintenanceStatusSubject = PublishSubject<MaintenanceStatus>()
  private let loginStatusSubject = PublishSubject<LoginStatusDTO>()
  private let playerBalanceSubject = PublishSubject<AccountCurrency>()
  private let errorSubject = PublishSubject<Error>()

  private let disposeBag = DisposeBag()

  private let signalRepository: SignalRepository

  init(signalRepository: SignalRepository) {
    self.signalRepository = signalRepository
  }

  // MARK: - Maintenance

  func observeMaintenanceStatus(useCase: GetSystemStatusUseCase) -> RxSwift.Observable<MaintenanceStatus> {
    maintenanceStatusSubject
      .asObservable()
      .do(onSubscribe: { [weak self] in
        guard let self else { return }

        self.fetchMaintenanceStatus(useCase: useCase)
        self.observeMaintenanceSignal(useCase: useCase)
      })
  }

  private func fetchMaintenanceStatus(useCase: GetSystemStatusUseCase) {
    useCase
      .fetchMaintenanceStatus()
      .subscribe(
        onSuccess: { [weak self] maintenanceStatus in
          guard let self else { return }

          self.maintenanceStatusSubject.onNext(maintenanceStatus)
        },
        onFailure: { [weak self] error in
          self?.errorSubject.onNext(error)
        })
      .disposed(by: disposeBag)
  }

  private func observeMaintenanceSignal(useCase: GetSystemStatusUseCase) {
    signalRepository
      .observeSystemSignal()
      .compactMap { backendSignal in
        backendSignal as? MaintenanceSignal
      }
      .subscribe(onNext: { [weak self] _ in
        guard let self else { return }

        self.fetchMaintenanceStatus(useCase: useCase)
      })
      .disposed(by: disposeBag)
  }

  // MARK: - Login

  func observeLoginStatus(useCase: AuthenticationUseCase) -> RxSwift.Observable<LoginStatusDTO> {
    loginStatusSubject
      .asObservable()
      .do(onSubscribe: { [weak self] in
        guard let self else { return }

        self.fetchLoginStatus(useCase: useCase)
        self.observeLoginSignal()
      })
  }

  private func fetchLoginStatus(useCase: AuthenticationUseCase) {
    useCase
      .isLogged()
      .subscribe(
        onSuccess: { [weak self] isLogin in
          guard let self else { return }

          self.loginStatusSubject
            .onNext(LoginStatusDTO.fetch(isLogin: isLogin))
        },
        onFailure: { [weak self] error in
          self?.errorSubject.onNext(error)
        })
      .disposed(by: disposeBag)
  }

  private func observeLoginSignal() {
    signalRepository
      .observeSystemSignal()
      .compactMap { backendSignal in
        backendSignal as? KickOutSignal
      }
      .subscribe(onNext: { [weak self] kickOutSignal in
        guard let self else { return }

        self.loginStatusSubject
          .onNext(LoginStatusDTO.kickout(type: kickOutSignal))
      })
      .disposed(by: disposeBag)
  }

  // MARK: - Balance

  func observePlayerBalance(useCase: PlayerDataUseCase) -> Observable<AccountCurrency> {
    playerBalanceSubject
      .asObservable()
      .do(onSubscribe: { [weak self] in
        guard let self else { return }

        self.fetchPlayerBalance(useCase: useCase)
        self.observeBalanceSignal(useCase: useCase)
      })
  }

  private func fetchPlayerBalance(useCase: PlayerDataUseCase) {
    useCase
      .getBalance()
      .subscribe(
        onSuccess: { [weak self] accountCurrency in
          guard let self else { return }

          self.playerBalanceSubject.onNext(accountCurrency)
        },
        onFailure: { [weak self] error in
          self?.errorSubject.onNext(error)
        })
      .disposed(by: disposeBag)
  }

  private func observeBalanceSignal(useCase: PlayerDataUseCase) {
    signalRepository
      .observeSystemSignal()
      .compactMap { backendSignal in
        backendSignal as? BalanceSignal
      }
      .subscribe(onNext: { [weak self] _ in
        guard let self else { return }

        self.fetchPlayerBalance(useCase: useCase)
      })
      .disposed(by: disposeBag)
  }

  // MARK: - Error Handle

  func errors() -> RxSwift.Observable<Error> {
    errorSubject.asObservable()
  }
}
