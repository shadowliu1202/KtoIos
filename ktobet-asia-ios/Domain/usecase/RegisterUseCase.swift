import Foundation
import RxSwift
import SharedBu

protocol RegisterUseCase {
  func register(account: UserAccount, password: UserPassword, locale: SupportLocale) -> Completable
  func loginFrom(otp: String) -> Single<Player>
  func checkAccountVerification(_ account: String) -> Single<Bool>
  func resendRegisterOtp() -> Completable
}

class RegisterUseCaseImpl: RegisterUseCase {
  var repoAuth: IAuthRepository!
  var repoPlayer: PlayerRepository!

  init(_ repoAuth: IAuthRepository, _ repoPlayer: PlayerRepository) {
    self.repoAuth = repoAuth
    self.repoPlayer = repoPlayer
  }

  func register(account: UserAccount, password: UserPassword, locale: SupportLocale) -> Completable {
    repoAuth.register(account, password, locale)
  }

  func loginFrom(otp: String) -> Single<Player> {
    repoAuth.authorize(otp).flatMap { [unowned self] _ -> Single<Player> in
      self.repoPlayer.loadPlayer().do(onSuccess: { [unowned self] player in
        self.repoPlayer.refreshHttpClient(playerLocale: player.locale())
      })
    }
  }

  func resendRegisterOtp() -> Completable {
    repoAuth.resendRegisterOtp()
  }

  func checkAccountVerification(_ account: String) -> Single<Bool> {
    repoAuth.checkRegistration(account)
  }
}
