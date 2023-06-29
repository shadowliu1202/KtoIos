import Foundation
import RxCocoa
import RxSwift
import SharedBu

class PlayerViewModel: CollectErrorViewModel {
  @Injected private var loading: Loading
  @Injected private var chatAppService: IChatAppService
  
  private let playerUseCase: PlayerDataUseCase
  private let authUseCase: AuthenticationUseCase

  private var loadingTracker: ActivityIndicator { loading.tracker }

  init(playerUseCase: PlayerDataUseCase, authUseCase: AuthenticationUseCase) {
    self.playerUseCase = playerUseCase
    self.authUseCase = authUseCase
  }

  func loadPlayerInfo() -> Observable<Player> {
    playerUseCase.loadPlayer().asObservable()
  }

  func getBalanceHiddenState(gameId: String) -> Bool {
    playerUseCase.getBalanceHiddenState(gameId: gameId)
  }

  func saveBalanceHiddenState(gameId: String, isHidden: Bool) {
    playerUseCase.setBalanceHiddenState(gameId: gameId, isHidden: isHidden)
  }

  func getPrivilege() -> Single<[LevelOverview]> {
    playerUseCase.getPrivilege()
  }

  func logout() -> Completable {
    closeChatRoomIfExist()
      .observe(on: MainScheduler.instance)
      .do(onCompleted: {
        Injectable.resetObjectScope(.locale)
        CustomServicePresenter.shared.closeService()
      })
      .concat(authUseCase.logout())
      .trackOnDispose(loadingTracker)
  }
  
  private func closeChatRoomIfExist() -> Completable {
    CustomServicePresenter.shared.csViewModel
      .currentChatRoom()
      .take(1)
      .flatMap { chatRoom -> Completable in
        if chatRoom.roomId.isEmpty {
          return Single.just(()).asCompletable()
        }
        else {
          return CustomServicePresenter.shared.csViewModel.closeChatRoom(forceExit: true).asCompletable()
        }
      }
      .asCompletable()
  }

  func checkIsLogged() -> Single<Bool> {
    authUseCase.isLogged()
  }

  func getPlayerInfo() -> Driver<Player?> {
    playerUseCase.loadPlayer()
      .map { $0 }
      .asDriver(onErrorRecover: { [weak self] error in
        self?.errorsSubject.onNext(error)

        return .just(nil)
      })
  }

  func getBalance() -> Driver<AccountCurrency?> {
    playerUseCase.getBalance()
      .map { $0 }
      .asDriver(onErrorRecover: { [weak self] error in
        self?.errorsSubject.onNext(error)

        return .just(nil)
      })
  }
}

enum AuthenticationState {
  case unauthenticated // Initial state, the user needs to authenticate
  case authenticated // The user has authenticated successfully
}
