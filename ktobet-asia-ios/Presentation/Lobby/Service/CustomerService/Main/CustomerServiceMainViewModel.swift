import Foundation
import RxCocoa
import RxSwift
import SharedBu

class CustomerServiceMainViewModel {
  func getIsChatRoomExist() -> Observable<Bool> {
    CustomServicePresenter.shared.getIsChatRoomExist()
  }

  func leftCustomerService() -> Observable<Void> {
    getIsChatRoomExist()
      .skip(1)
      .filter { $0 == false }
      .map { _ in () }
  }
}
