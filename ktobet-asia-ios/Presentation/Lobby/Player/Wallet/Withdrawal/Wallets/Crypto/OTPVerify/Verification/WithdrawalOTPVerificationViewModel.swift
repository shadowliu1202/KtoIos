import RxSwift
import SharedBu
import SwiftUI

class WithdrawalOTPVerificationViewModel:
  WithdrawalOTPVerificationViewModelProtocol &
  ObservableObject &
  CollectErrorViewModel
{
  @Published private(set) var headerTitle = ""
  @Published private(set) var sentCodeMessage = ""

  @Published private(set) var otpCodeLength = 6
  @Published private(set) var timerText = ""

  @Published private(set) var isLoading = true

  @Published private(set) var isResentOTPEnable = false
  @Published private(set) var isOTPVerifyInProgress = false

  @Published private(set) var isVerifiedFail = false

  @Published var otpCode = ""

  private static let countdownMinute = 4

  private let playerConfiguration: PlayerConfiguration
  private let withdrawalAppService: IWithdrawalAppService
  private let playerDataUseCase: PlayerDataUseCase

  private let countdownTimer = CombineCountdownTimer()

  private let disposeBag = DisposeBag()

  private var accountType: SharedBu.AccountType?

  init(
    _ playerConfiguration: PlayerConfiguration,
    _ playerDataUseCase: PlayerDataUseCase,
    _ withdrawalAppService: IWithdrawalAppService)
  {
    self.playerDataUseCase = playerDataUseCase
    self.playerConfiguration = playerConfiguration
    self.withdrawalAppService = withdrawalAppService
  }

  func setup(accountType: SharedBu.AccountType) {
    setupIsVerifiedFailRefreshing()

    cacheAccountType(accountType)

    initHeaderTitle()
    initSentCodeMessage()
    initOTPCodeLength()

    startCountdownTimer()
  }

  private func setupIsVerifiedFailRefreshing() {
    $otpCode
      .skipOneThenAsDriver()
      .drive(onNext: { [weak self] _ in
        if self?.isVerifiedFail == true {
          self?.isVerifiedFail = false
        }
      })
      .disposed(by: disposeBag)
  }

  private func cacheAccountType(_ accountType: SharedBu.AccountType) {
    self.accountType = accountType
  }

  private func initHeaderTitle() {
    guard let accountType else { return }

    switch accountType {
    case .phone:
      headerTitle = Localize.string("common_verify_mobile")
    case .email:
      headerTitle = Localize.string("common_verify_email")
    default:
      fatalError("should not reach here.")
    }
  }

  private func initSentCodeMessage() {
    guard let accountType else { return }

    playerDataUseCase
      .loadPlayer()
      .map { player in
        player.playerInfo.contact
      }
      .observe(on: MainScheduler.instance)
      .do(onSuccess: { [weak self] _ in
        self?.isLoading = false
      })
      .subscribe(
        onSuccess: { [weak self] contactInfo in
          switch accountType {
          case .phone:
            self?.sentCodeMessage = Localize.string("common_otp_sent_content_mobile")
              + "\n"
              + (contactInfo.mobile ?? "")
          case .email:
            self?.sentCodeMessage = Localize.string("common_otp_sent_content_mobile")
              + "\n"
              + (contactInfo.email ?? "")
          default:
            fatalError("should not reach here.")
          }
        },
        onFailure: { [weak self] error in
          self?.errorsSubject
            .onNext(error)
        })
      .disposed(by: disposeBag)
  }

  private func initOTPCodeLength() {
    guard let accountType else { return }

    switch playerConfiguration.supportLocale {
    case
      is SupportLocale.China,
      is SupportLocale.Unknown:
      otpCodeLength = 6

    case is SupportLocale.Vietnam:
      switch accountType {
      case .phone:
        otpCodeLength = 4
      case .email:
        otpCodeLength = 6
      default:
        fatalError("should not reach here.")
      }

    default:
      fatalError("should not reach here.")
    }
  }

  private func startCountdownTimer() {
    countdownTimer
      .start(
        seconds: 60 * Self.countdownMinute,
        onTick: { [weak self] timeRemaining in
          let minutes = timeRemaining / 60
          let remainingSeconds = timeRemaining % 60

          self?.timerText = String(format: "%02d:%02d", minutes, remainingSeconds)
        },
        completion: { [weak self] in
          self?.isResentOTPEnable = true
        })
  }

  func verifyOTP(onCompleted: (() -> Void)?, onErrorRedirect: ((Error) -> Void)?) {
    guard let accountType else { return }

    Completable.from(
      withdrawalAppService.confirmVerificationOTP(otp: otpCode, type: accountType))
      .observe(on: MainScheduler.instance)
      .do(
        onSubscribe: { self.isOTPVerifyInProgress = true },
        onDispose: { self.isOTPVerifyInProgress = false })
      .subscribe(
        onCompleted: { onCompleted?() },
        onError: {
          switch $0 {
          case let error as WithdrawalDto.VerifyConfirmErrorStatus:
            switch error {
            case is WithdrawalDto.VerifyConfirmErrorStatusWrongOtp:
              self.isVerifiedFail = true
            default:
              onErrorRedirect?(error)
            }
          default:
            self.errorsSubject.onNext($0)
          }
        })
      .disposed(by: disposeBag)
  }

  func resendOTP(onCompleted: (() -> Void)?, onErrorRedirect: ((Error) -> Void)?) {
    guard let accountType else { return }
    
    Completable.from(
      withdrawalAppService.resendVerificationOTP(type: accountType))
      .observe(on: MainScheduler.instance)
      .do(
        onError: { _ in self.isResentOTPEnable = true },
        onSubscribe: { self.isResentOTPEnable = false })
      .subscribe(
        onCompleted: {
          self.startCountdownTimer()
          onCompleted?()
        },
        onError: {
          switch $0 {
          case let error as WithdrawalDto.VerifyRequestErrorStatus:
            onErrorRedirect?(error)
          default:
            self.errorsSubject.onNext($0)
          }
        })
      .disposed(by: disposeBag)
  }

  func getSupportLocale() -> SupportLocale {
    playerConfiguration.supportLocale
  }
}
