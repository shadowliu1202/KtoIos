import Foundation
import RxSwift
import sharedbu

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
      .catch { throw ($0 is PlayerRegisterBlock) ? KtoPlayerRegisterBlock() : $0 }
  }

  func loginFrom(otp: String) -> Single<Player> {
    repoAuth.authorize(otp)
      .flatMap { [unowned self] _ -> Single<Player> in
        repoPlayer.loadPlayer()
          .do(onSuccess: { player in
            handlePlayerSessionChange(locale: player.locale())
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
