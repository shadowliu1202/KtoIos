import Foundation
import RxCocoa
import RxSwift
import SharedBu

class SideMenuViewModel: CollectErrorViewModel {
  private let maintenanceStatusSubject = PublishSubject<MaintenanceStatus>()
  private let playerBalanceSubject = PublishSubject<AccountCurrency>()

  private let observeSystemMessageUseCase: ObserveSystemMessageUseCase
  private let playerDataUseCase: PlayerDataUseCase
  private let getSystemStatusUseCase: GetSystemStatusUseCase
  private let authenticationUseCase: AuthenticationUseCase

  private let disposeBag = DisposeBag()

  let features = Observable<[FeatureItem]>.from(optional: [
    FeatureItem(type: .deposit, name: Localize.string("common_deposit"), icon: "Deposit"),
    FeatureItem(type: .withdraw, name: Localize.string("common_withdrawal"), icon: "Withdrawl"),
    FeatureItem(type: .callService, name: Localize.string("common_customerservice"), icon: "Customer Service"),
    FeatureItem(type: .logout, name: Localize.string("common_logout"), icon: "Logout")
  ])

  lazy var products = getProducts()

  var currentSelectedCell: ProductItemCell?
  var currentSelectedProductType: ProductType?

  init(
    observeSystemMessageUseCase: ObserveSystemMessageUseCase,
    playerDataUseCase: PlayerDataUseCase,
    getSystemStatusUseCase: GetSystemStatusUseCase,
    authenticationUseCase: AuthenticationUseCase)
  {
    self.observeSystemMessageUseCase = observeSystemMessageUseCase
    self.playerDataUseCase = playerDataUseCase
    self.getSystemStatusUseCase = getSystemStatusUseCase
    self.authenticationUseCase = authenticationUseCase
  }

  private func getProducts() -> [ProductItem] {
    let titles = [
      Localize.string("common_sportsbook"),
      Localize.string("common_casino"),
      Localize.string("common_slot"),
      Localize.string("common_keno"),
      Localize.string("common_p2p"),
      Localize.string("common_arcade")
    ]

    let imgs = ["SBK", "Casino", "Slot", "Number Game", "P2P", "Arcade"]
    let type: [ProductType] = [.sbk, .casino, .slot, .numbergame, .p2p, .arcade]
    var arr = [ProductItem]()

    titles.enumerated()
      .forEach { index, _ in
        let item = ProductItem(title: titles[index], image: imgs[index], type: type[index])
        arr.append(item)
      }

    return arr
  }

  func observeMaintenanceStatus() -> Observable<MaintenanceStatus> {
    maintenanceStatusSubject
      .asObservable()
      .do(onSubscribe: { [weak self] in
        guard let self else { return }

        self.observeSystemMessageUseCase
          .observeMaintenanceStatus(useCase: self.getSystemStatusUseCase)
          .subscribe(onNext: { [weak self] maintenanceStatus in
            guard let self else { return }

            self.maintenanceStatusSubject
              .onNext(maintenanceStatus)
          })
          .disposed(by: self.disposeBag)
      })
  }

  func observePlayerBalance() -> Observable<AccountCurrency> {
    playerBalanceSubject
      .asObservable()
      .do(onSubscribe: { [weak self] in
        guard let self else { return }

        self.observeSystemMessageUseCase
          .observePlayerBalance(useCase: self.playerDataUseCase)
          .subscribe(onNext: { [weak self] accountCurrency in
            guard let self else { return }

            self.playerBalanceSubject
              .onNext(accountCurrency)
          })
          .disposed(by: self.disposeBag)
      })
  }

  func observeLoginStatus() -> Observable<LoginStatusDTO> {
    self.observeSystemMessageUseCase
      .observeLoginStatus(useCase: self.authenticationUseCase)
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

  func fetchData() {
    fetchMaintenanceStatus()
    fetchPlayerBalance()
  }

  func fetchMaintenanceStatus() {
    getSystemStatusUseCase
      .fetchMaintenanceStatus()
      .subscribe(
        onSuccess: { [weak self] maintenanceStatus in
          guard let self else { return }

          self.maintenanceStatusSubject.onNext(maintenanceStatus)
        },
        onFailure: { [weak self] error in
          guard let self else { return }

          self.errorsSubject.onNext(error)
        })
      .disposed(by: disposeBag)
  }

  func fetchPlayerBalance() {
    playerDataUseCase
      .getBalance()
      .subscribe(
        onSuccess: { [weak self] accountCurrency in
          guard let self else { return }

          self.playerBalanceSubject.onNext(accountCurrency)
        },
        onFailure: { [weak self] error in
          guard let self else { return }

          self.errorsSubject.onNext(error)
        })
      .disposed(by: disposeBag)
  }
}

struct ProductItem {
  var title = ""
  var image = ""
  var type = ProductType.none
  var maintainTime: OffsetDateTime?
}

struct FeatureItem {
  var type: FeatureType
  var name: String
  var icon: String
}
