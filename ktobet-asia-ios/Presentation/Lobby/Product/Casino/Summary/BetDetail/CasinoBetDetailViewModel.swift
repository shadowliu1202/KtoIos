import Foundation
import RxSwift
import SharedBu
import SwiftUI

protocol ICasinoBetDetailViewModel {
  var betDetail: CasinoDTO.BetDetail? { get }
  
  func setup(with wagerID: String)
  
  func getSupportLocale() -> SupportLocale
}

class CasinoBetDetailViewModel:
  ICasinoBetDetailViewModel &
  ObservableObject &
  CollectErrorViewModel
{
  @Published var betDetail: CasinoDTO.BetDetail? = nil
  
  @Injected var casinoMyBetAppService: ICasinoMyBetAppService
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
    Single.from(
      casinoMyBetAppService.getDetail(id: wagerID))
      .observe(on: MainScheduler.instance)
      .subscribe(
        onSuccess: { self.betDetail = $0 },
        onFailure: { self.errorsSubject.onNext($0) })
      .disposed(by: disposeBag)
  }
  
  func getSupportLocale() -> SupportLocale {
    playerConfiguration.supportLocale
  }
}
