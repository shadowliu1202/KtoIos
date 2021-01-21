import Foundation
import RxSwift



class SystemViewModel {
    private var systemUseCase : SystemSignalRUseCase!
    
    init(systemUseCase :SystemSignalRUseCase) {
        self.systemUseCase = systemUseCase
    }
    
    func observeSystemMessage() -> Observable<Target> {
        self.systemUseCase.observeSystemMessage()
    }
    
    func disconnectService() {
        self.systemUseCase.disconnectService()
    }
}
