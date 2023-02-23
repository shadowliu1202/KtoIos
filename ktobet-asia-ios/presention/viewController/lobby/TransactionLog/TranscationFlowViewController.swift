import RxSwift
import SharedBu
import UIKit

protocol TranscationFlowDelegate: AnyObject {
  func displaySportsBookDetail(wagerId: String)
}

class TranscationFlowController {
  private weak var vc: UIViewController?
  private var navi: UINavigationController? {
    vc?.navigationController
  }

  var disposeBag: DisposeBag

  weak var delegate: TranscationFlowDelegate?

  init(_ vc: UIViewController?, disposeBag: DisposeBag) {
    self.vc = vc
    self.disposeBag = disposeBag
  }

  func goNext(_ wagerId: String) {
    goCasinoDetail(wagerId)
  }

  func goNext(_ transactionLog: TransactionLog) {
    switch transactionLog {
    case let log as TransactionLog.GameProduct:
      consider(gameProduct: log)
    case let log as TransactionLog.MoneyTransfer:
      consider(moneyTransfer: log)
    case is TransactionLog.GameBonus,
         is TransactionLog.Log:
      goTransactionLogDetail(LogDetail(title: transactionLog.name, transactionId: transactionLog.detailId()))
    default:
      break
    }
  }

  private func consider(gameProduct: TransactionLog.GameProduct) {
    switch gameProduct {
    case is TransactionLog.GameProductGeneral:
      goTransactionLogDetail(LogDetail(title: gameProduct.name, transactionId: gameProduct.detailId()))
    case let casinoLog as TransactionLog.GameProductCasino:
      consider(casino: casinoLog)
    case let sportLog as TransactionLog.GameProductSportsBook:
      displaySportsBookDetail(wagerId: sportLog.detailId())
    case let numbergameLog as TransactionLog.GameProductNumberGame:
      consider(numbergame: numbergameLog)
    default:
      break
    }
  }

  private func consider(moneyTransfer: TransactionLog.MoneyTransfer) {
    switch moneyTransfer {
    case let depositLog as TransactionLog.MoneyTransferDeposit:
      goDepositDetail(depositLog)
    case let withdrawalLog as TransactionLog.MoneyTransferWithdrawal:
      goWithdrawalDetail(withdrawalLog)
    default:
      break
    }
  }

  private func consider(casino: TransactionLog.GameProductCasino) {
    switch casino {
    case let log as TransactionLog.GameProductCasinoGeneral:
      self.goTransactionLogDetail(LogDetail(title: log.name, transactionId: log.detailId(), isSmartBet: log.isSmartBet))
    case is TransactionLog.GameProductCasinoGameResultMode:
      self.goCasinoDetail(casino.detailId())
    default:
      break
    }
  }

  private func consider(numbergame: TransactionLog.GameProductNumberGame) {
    switch numbergame {
    case is TransactionLog.GameProductNumberGameGameResultMode:
      goNumberGameDetail(numbergame.detailId())
    case is TransactionLog.GameProductNumberGameGeneral:
      goTransactionLogDetail(LogDetail(title: numbergame.name, transactionId: numbergame.detailId()))
    default:
      break
    }
  }

  private func goTransactionLogDetail(_ param: LogDetail) {
    guard
      let detailViewController = UIStoryboard(name: "TransactionLog", bundle: nil)
        .instantiateViewController(withIdentifier: "TransactionLogDetailViewController") as? TransactionLogDetailViewController
    else { return }
    detailViewController.param = param
    self.navi?.pushViewController(detailViewController, animated: true)
  }

  private func goCasinoDetail(_ wagerId: String) {
    guard
      let detail = UIStoryboard(name: "Casino", bundle: nil)
        .instantiateViewController(withIdentifier: "CasinoDetailViewController") as? CasinoDetailViewController else { return }
    detail.wagerId = wagerId
    self.navi?.pushViewController(detail, animated: true)
  }

  private func goNumberGameDetail(_ wagerId: String) {
    self.vc?.view.isUserInteractionEnabled = false
    let viewModel = Injectable.resolve(NumberGameRecordViewModel.self)!
    viewModel.getGameDetail(wagerId: wagerId).subscribe(onSuccess: { [weak self] result in
      guard
        let detail = UIStoryboard(name: "NumberGame", bundle: nil)
          .instantiateViewController(
            withIdentifier: "NumberGameMyBetDetailViewController") as? NumberGameMyBetDetailViewController
      else { return }
      detail.details = [result]
      detail.isViewPager = false
      self?.navi?.pushViewController(detail, animated: true)
      self?.vc?.view.isUserInteractionEnabled = true
    }, onError: { [weak self] error in
      self?.vc?.handleErrors(error)
      self?.vc?.view.isUserInteractionEnabled = true
    }).disposed(by: self.disposeBag)
  }

  private func goDepositDetail(_ depositLog: TransactionLog.MoneyTransferDeposit) {
    let storyboard = UIStoryboard(name: "Deposit", bundle: Bundle.main)
    let vc = storyboard.instantiateViewController(withIdentifier: "DepositRecordContainer") as! DepositRecordContainer
    vc.displayId = depositLog.detailId()
    vc.transactionType = depositLog.transferType
    self.navi?.pushViewController(vc, animated: true)
  }

  private func goWithdrawalDetail(_ log: TransactionLog.MoneyTransferWithdrawal) {
    let storyboard = UIStoryboard(name: "Withdrawal", bundle: Bundle.main)
    let vc = storyboard.instantiateViewController(withIdentifier: "WithdrawlRecordContainer") as! WithdrawlRecordContainer
    vc.displayId = log.detailId()
    vc.transactionTransactionType = log.transferType
    self.navi?.pushViewController(vc, animated: true)
  }

  private func displaySportsBookDetail(wagerId: String) {
    delegate?.displaySportsBookDetail(wagerId: wagerId)
  }
}
