import RxCocoa
import RxSwift
import sharedbu

protocol WithdrawalRequestVerifiable { }

extension WithdrawalRequestVerifiable {
  func observeValidation(
    withdrawalService: IWithdrawalAppService,
    walletId: String,
    amountDriver: Driver<String>) -> Observable<String?>
  {
    Observable.from(
      withdrawalService.verifyWithdrawalAmount(
        walletId: walletId,
        verifyAmount: amountDriver
          .map { $0.toAccountCurrency() }
          .toWrapper()))
      .map {
        var textKey: String?

        switch $0 {
        case .beyondrange:
          textKey = "withdrawal_amount_beyond_range"
        case .belowrange:
          textKey = "withdrawal_amount_below_range"
        case .exceeddailylimit:
          textKey = "withdrawal_amount_exceed_daily_limit"
        case .notenoughbalance:
          textKey = "withdrawal_balance_not_enough"
        case .exceeddailycount:
          textKey = nil // should not be here
        case .valid:
          textKey = ""
        default:
          textKey = nil
        }

        return textKey == nil ? nil : Localize.string(textKey!)
      }
  }
}
