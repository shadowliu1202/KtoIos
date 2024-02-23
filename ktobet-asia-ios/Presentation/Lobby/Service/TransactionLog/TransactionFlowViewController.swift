import RxSwift
import sharedbu
import UIKit

protocol TransactionFlowDelegate: AnyObject {
  func getIsCasinoWagerDetailExist(by wagerID: String) async -> Bool?
  
  func getIsP2PWagerDetailExist(by wagerID: String) async -> Bool?
  
  func displaySportsBookDetail(wagerId: String)
}

class TransactionFlowController {
  private weak var vc: UIViewController?
  private var navi: UINavigationController? {
    vc?.navigationController
  }

  var disposeBag: DisposeBag

  weak var delegate: TransactionFlowDelegate?

  init(_ vc: UIViewController?, disposeBag: DisposeBag) {
    self.vc = vc
    self.disposeBag = disposeBag
  }

  func goNext(_ transactionLog: TransactionDTO.Log) {
    switch transactionLog.type {
    case .bonus,
         .general:
      goTransactionLogDetail(LogDetail(title: transactionLog.title, transactionId: transactionLog.detailId))
    case .deposit:
      goDepositDetail(transactionLog)
    case .withdrawal:
      goWithdrawalDetail(transactionLog)
    case .sportsBook:
      displaySportsBookDetail(wagerId: transactionLog.detailId)
    case .casino:
      considerCasino(transactionLog)
    case .numberGame:
      considerNumbergame(transactionLog)
    case .p2P:
      considerP2P(transactionLog)
    }
  }

  private func considerCasino(_ log: TransactionDTO.Log) {
    guard let detailOption = log.detailOption as? DetailOption.Casino else { return }
    
    if detailOption.hasGameResult {
      goCasinoDetail(log.detailId)
    }
    else {
      goTransactionLogDetail(LogDetail(title: log.title, transactionId: log.detailId, isSmartBet: detailOption.isSmartBet))
    }
  }
  
  private func considerNumbergame(_ log: TransactionDTO.Log) {
    guard let detailOption = log.detailOption as? DetailOption.NumberGame else { return }
    
    if detailOption.hasGameResult {
      goNumberGameDetail(log.detailId)
    }
    else {
      goTransactionLogDetail(LogDetail(title: log.title, transactionId: log.id))
    }
  }
  
  private func considerP2P(_ log: TransactionDTO.Log) {
    guard let detailOption = log.detailOption as? DetailOption.P2P else { return }
    
    if detailOption.hasGameResult {
      goP2PDetail(log.detailId)
    }
    else {
      goTransactionLogDetail(LogDetail(title: log.title, transactionId: log.detailId))
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

  func goCasinoDetail(_ wagerId: String) {
    self.navi?.pushViewController(CasinoBetDetailViewController(wagerID: wagerId), animated: true)
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
    }, onFailure: { [weak self] error in
      self?.vc?.handleErrors(error)
      self?.vc?.view.isUserInteractionEnabled = true
    }).disposed(by: self.disposeBag)
  }

  private func goDepositDetail(_ log: TransactionDTO.Log) {
    let detailMainViewController = DepositRecordDetailMainViewController(displayId: log.detailId)

    navi?.pushViewController(detailMainViewController, animated: true)
  }

  private func goWithdrawalDetail(_ log: TransactionDTO.Log) {
    let detailMainViewController = WithdrawalRecordDetailMainViewController(displayId: log.detailId)

    navi?.pushViewController(detailMainViewController, animated: true)
  }

  private func displaySportsBookDetail(wagerId: String) {
    delegate?.displaySportsBookDetail(wagerId: wagerId)
  }
  
  func goP2PDetail(_ wagerID: String) {
    navi?.pushViewController(P2PBetDetailViewController(wagerID: wagerID), animated: true)
  }
}
