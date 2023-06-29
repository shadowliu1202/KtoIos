import Foundation
import RxCocoa
import RxSwift
import SharedBu

class CustomerServiceMainViewModel {
  private let chatAppService: IChatAppService
  
  init(_ chatAppService: IChatAppService) {
    self.chatAppService = chatAppService
  }
  
  func getIsChatRoomExist() -> Observable<Bool> {
    Observable
      .from(chatAppService.observeChatRoom())
      .map { $0.value == nil ? false : true }
  }
  
  func leftCustomerService() -> Observable<Void> {
    getIsChatRoomExist()
      .skip(1)
      .filter { $0 == false }
      .map { _ in () }
  }
}
