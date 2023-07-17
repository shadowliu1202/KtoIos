import Foundation
import RxSwift
import SharedBu
import SwiftUI

protocol IP2PBetDetailViewModel {
  var betDetail: P2PDTO.BetDetail? { get }
  
  func setup(with wagerID: String)
  
  func getSupportLocale() -> SupportLocale
}

class P2PBetDetailViewModel:
  IP2PBetDetailViewModel &
  ObservableObject &
  CollectErrorViewModel
{
  @Published var betDetail: P2PDTO.BetDetail? = nil
  
  @Injected var p2pAppService: IP2PAppService
  @Injected var playerConfiguration: PlayerConfiguration
  
  private let disposeBag = DisposeBag()
  
  override init() {
    Logger.shared.info("\(type(of: self)) init")
  }
  
  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
  
  func setup(with wagerID: String) {
    bindBetDetail(wagerID)
  }
  
  func bindBetDetail(_ wagerID: String) {
    Observable.from(
      p2pAppService.getDetail(id: wagerID))
      .observe(on: MainScheduler.instance)
      .subscribe(
        onNext: { self.betDetail = $0 },
        onError: { self.errorsSubject.onNext($0) })
      .disposed(by: disposeBag)
  }
  
  func getSupportLocale() -> SupportLocale {
    playerConfiguration.supportLocale
  }
}
