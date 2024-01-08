import Combine
import Foundation
import RxCocoa
import RxSwift
import sharedbu

class CustomerServiceViewModel {
  private let chatAppService: ICustomerServiceAppService
  private let playerConfiguration: PlayerConfiguration
  private let loading: Loading
  
  private let chatRoomTempMapper = ChatRoomTempMapper()
  
  private lazy var observeChatRoom = Observable.from(chatAppService.observeChatRoom()).share(replay: 1)

  lazy var chatRoomUnreadMessage = currentChatRoom()
    .compactMap { [weak chatRoomTempMapper] in chatRoomTempMapper?.convertToUnreadMessages($0) }

  lazy var chatRoomStatus = currentChatRoom()
    .compactMap { [weak chatRoomTempMapper] in chatRoomTempMapper?.convertToStatus($0) }
      
  lazy var isPlayerInChat = chatRoomStatus.map { $0 != PortalChatRoom.ConnectStatus.notexist }
  
  init(
    _ chatAppService: ICustomerServiceAppService,
    _ playerConfiguration: PlayerConfiguration,
    _ loading: Loading)
  {
    self.chatAppService = chatAppService
    self.playerConfiguration = playerConfiguration
    self.loading = loading
  }

  func currentChatRoom() -> Observable<CustomerServiceDTO.ChatRoom> {
    observeChatRoom
  }

  func closeChatRoom(forceExit: Bool = false) -> Single<CustomerServiceDTO.ExitChat> {
    Single.from(chatAppService.exit(forceExit: forceExit))
      .trackOnDispose(loading.tracker)
  }
  
  func hasPreChatSurvey() -> Single<Bool> {
    Single.from(chatAppService.hasPreChatSurvey()).map { $0.toBool() }
  }
}
