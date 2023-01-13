import Foundation
import RxSwift
import RxCocoa
import SharedBu

class CustomerServiceMainViewModel {
    
    func getIsChatRoomExist() -> Observable<Bool> {
        CustomServicePresenter.shared.getIsChatRoomExist()
    }
    
    func leftCustomerService() -> Observable<Void> {
        return getIsChatRoomExist()
            .skip(1)
            .filter { $0 == false }
            .map { _ in () }
    }
}
