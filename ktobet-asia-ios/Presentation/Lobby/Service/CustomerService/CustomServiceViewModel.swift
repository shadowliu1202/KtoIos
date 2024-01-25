import Combine
import Foundation
import RxCocoa
import RxSwift
import sharedbu

class CustomerServiceViewModel {
  private let chatAppService: ICustomerServiceAppService
  private let playerConfiguration: PlayerConfiguration
  private let loading: Loading
  
  private lazy var observeChatRoom = Observable.from(chatAppService.observeChatRoom())
    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
    .share(replay: 1)

  lazy var chatRoomUnreadMessage = observeChatRoom.map { $0.unReadMessage }
  lazy var chatRoomStatus = observeChatRoom.map { $0.status }
  lazy var isPlayerInChat = chatRoomStatus.map { $0 != Connection.StatusNotExist() }
  
  init(
    _ chatAppService: ICustomerServiceAppService,
    _ playerConfiguration: PlayerConfiguration,
    _ loading: Loading)
  {
    self.chatAppService = chatAppService
    self.playerConfiguration = playerConfiguration
    self.loading = loading
  }

  func closeChatRoom(forceExit: Bool = false) -> Single<CustomerServiceDTO.ExitChat> {
    Single.from(chatAppService.exit(forceExit: forceExit))
      .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
      .trackOnDispose(loading.tracker)
  }
  
  func hasPreChatSurvey() -> Single<Bool> {
    Single.from(chatAppService.hasPreChatSurvey()).map { $0.toBool() }
  }
}
