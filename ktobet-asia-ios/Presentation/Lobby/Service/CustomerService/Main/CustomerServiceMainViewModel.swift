import Foundation
import RxCocoa
import RxSwift
import sharedbu

class CustomerServiceMainViewModel {
  private let chatAppService: IChatAppService
  
  init(_ chatAppService: IChatAppService) {
    self.chatAppService = chatAppService
  }
  
  func getIsChatRoomExist() -> Observable<Bool> {
    Observable
      .from(chatAppService.observeChatRoom())
      .map { $0.status != sharedbu.Connection.StatusNotExist() }
  }
  
  func leftCustomerService() -> Observable<Void> {
    getIsChatRoomExist()
      .skip(1)
      .filter { $0 == false }
      .map { _ in () }
  }
}
