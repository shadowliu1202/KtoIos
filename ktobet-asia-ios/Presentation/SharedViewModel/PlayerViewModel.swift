import Foundation
import RxCocoa
import RxSwift
import SharedBu

class PlayerViewModel: CollectErrorViewModel {
  @Injected private var loading: Loading
  
  private let authUseCase: AuthenticationUseCase

  private var loadingTracker: ActivityIndicator { loading.tracker }

  init(authUseCase: AuthenticationUseCase) {
    self.authUseCase = authUseCase
  }

  func logout() -> Completable {
    CustomServicePresenter.shared.closeService()
      .concat(authUseCase.logout())
      .trackOnDispose(loadingTracker)
  }

  func checkIsLogged() -> Single<Bool> {
    authUseCase.isLogged()
  }
}
