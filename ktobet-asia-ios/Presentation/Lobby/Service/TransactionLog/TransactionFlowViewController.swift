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
  private var decideNavigationTask: Task<Void, Never>?
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
    case .sportsbook:
      displaySportsBookDetail(wagerId: transactionLog.detailId)
    case .casino:
      considerCasino(transactionLog)
    case .numbergame:
      considerNumbergame(transactionLog)
    case .p2p:
      considerP2P(transactionLog)
    default: break
    }
  }

  private func considerCasino(_ log: TransactionDTO.Log) {
    guard let detailOption = log.detailOption as? DetailOption.Casino else { return }
    switch detailOption.detailType {
    case .general:
      goTransactionLogDetail(LogDetail(title: log.title, transactionId: log.id, isSmartBet: detailOption.isSmartBet))
    case .gameresultmode:
      goCasinoDetail(log.detailId)
    case .unknowndetail:
      navigateBaseOnCasinoHasDetail(name: log.title, transactionId: log.id, wagerID: log.detailId)
    default: break
    }
  }
  
  private func navigateBaseOnCasinoHasDetail(name: String, transactionId: String, wagerID: String) {
    guard let delegate, decideNavigationTask == nil else { return }
    
    decideNavigationTask = Task {
      guard let isWagerDetailExist = await delegate.getIsCasinoWagerDetailExist(by: wagerID)
      else {
        resetDecideNavigationTask()
        return
      }

      await MainActor.run {
        isWagerDetailExist
          ? goCasinoDetail(wagerID)
          : goTransactionLogDetail(LogDetail(title: name, transactionId: transactionId))
        
        resetDecideNavigationTask()
      }
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
    
    if detailOption.isUnknownDetail {
      navigateBaseOnP2PHasDetail(name: log.title, transactionId: log.id, wagerID: log.detailId)
    }
    else {
      goTransactionLogDetail(LogDetail(title: log.title, transactionId: log.id))
    }
  }
  
  private func navigateBaseOnP2PHasDetail(name: String, transactionId: String, wagerID: String) {
    guard let delegate, decideNavigationTask == nil else { return }
    
    decideNavigationTask = Task {
      guard let isWagerDetailExist = await delegate.getIsP2PWagerDetailExist(by: wagerID)
      else {
        resetDecideNavigationTask()
        return
      }

      await MainActor.run {
        isWagerDetailExist
          ? goP2PMyBetDetail(wagerID)
          : goTransactionLogDetail(LogDetail(title: name, transactionId: transactionId))
        
        resetDecideNavigationTask()
      }
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
  
  private func goP2PMyBetDetail(_ wagerID: String) {
    navi?.pushViewController(P2PBetDetailViewController(wagerID: wagerID), animated: true)
  }
  
  func navigateBaseOnProductHasDetail(type: ProductType, gameName: String, transactionId: String, wagerID: String) {
    switch type {
    case .casino: navigateBaseOnCasinoHasDetail(name: gameName, transactionId: transactionId, wagerID: wagerID)
    case .p2p: navigateBaseOnP2PHasDetail(name: gameName, transactionId: transactionId, wagerID: wagerID)
    default: break
    }
  }
  
  func resetDecideNavigationTask() {
    decideNavigationTask = nil
  }
}
