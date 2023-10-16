import Combine
import Foundation
import RxSwift
import sharedbu
import SwiftUI

protocol ICasinoBetDetailViewModel {
  var betDetail: CasinoDTO.BetDetail? { get }
  
  func setup(with wagerID: String)
  
  func getSupportLocale() -> SupportLocale
}

class CasinoBetDetailViewModel:
  ICasinoBetDetailViewModel &
  ObservableObject &
  ErrorCollectViewModel
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
    AnyPublisher.from(casinoMyBetAppService.getDetail(id: wagerID))
      .receive(on: DispatchQueue.main)
      .redirectErrors(to: self)
      .assignOptional(to: &$betDetail)
  }
  
  func getSupportLocale() -> SupportLocale {
    playerConfiguration.supportLocale
  }
}
