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
    case let p2pLog as TransactionLog.GameProductP2P:
      consider(p2pLog)
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
    case let casino as TransactionLog.GameProductCasinoGeneral:
      goTransactionLogDetail(LogDetail(title: casino.name, transactionId: casino.detailId(), isSmartBet: casino.isSmartBet))
    case is TransactionLog.GameProductCasinoGameResultMode:
      goCasinoDetail(casino.detailId())
    case is TransactionLog.GameProductCasinoUnknownDetail:
      navigateBaseOnCasinoHasDetail(name: casino.name, displayID: casino.id_, wagerID: casino.detailId())
    default:
      break
    }
  }
  
  private func navigateBaseOnCasinoHasDetail(name: String, displayID: String, wagerID: String) {
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
          : goTransactionLogDetail(LogDetail(title: name, transactionId: displayID))
        
        resetDecideNavigationTask()
      }
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
  
  private func consider(_ p2pLog: TransactionLog.GameProductP2P) {
    switch p2pLog {
    case is TransactionLog.GameProductP2PGeneral:
      goTransactionLogDetail(LogDetail(title: p2pLog.name, transactionId: p2pLog.id_))
    case is TransactionLog.GameProductP2PUnknownDetail:
      navigateBaseOnP2PHasDetail(name: p2pLog.name, displayID: p2pLog.id_, wagerID: p2pLog.detailId())
    default:
      break
    }
  }
  
  private func navigateBaseOnP2PHasDetail(name: String, displayID: String, wagerID: String) {
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
          : goTransactionLogDetail(LogDetail(title: name, transactionId: displayID))
        
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

  private func goDepositDetail(_ depositLog: TransactionLog.MoneyTransferDeposit) {
    let detailMainViewController = DepositRecordDetailMainViewController(
      displayId: depositLog.detailId(),
      transactionType: depositLog.transferType)

    navi?.pushViewController(detailMainViewController, animated: true)
  }

  private func goWithdrawalDetail(_ log: TransactionLog.MoneyTransferWithdrawal) {
    let detailMainViewController = WithdrawalRecordDetailMainViewController(
      displayId: log.detailId(),
      transactionType: log.transferType)

    navi?.pushViewController(detailMainViewController, animated: true)
  }

  private func displaySportsBookDetail(wagerId: String) {
    delegate?.displaySportsBookDetail(wagerId: wagerId)
  }
  
  private func goP2PMyBetDetail(_ wagerID: String) {
    navi?.pushViewController(P2PBetDetailViewController(wagerID: wagerID), animated: true)
  }
  
  func navigateBaseOnProductHasDetail(type: ProductType, gameName: String, displayID: String, wagerID: String) {
    switch type {
    case .casino: navigateBaseOnCasinoHasDetail(name: gameName, displayID: displayID, wagerID: wagerID)
    case .p2p: navigateBaseOnP2PHasDetail(name: gameName, displayID: displayID, wagerID: wagerID)
    default: break
    }
  }
  
  func resetDecideNavigationTask() {
    decideNavigationTask = nil
  }
}
