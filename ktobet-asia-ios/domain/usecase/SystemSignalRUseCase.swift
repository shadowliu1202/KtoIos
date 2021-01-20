import Foundation
import RxSwift

protocol SystemSignalRUseCase {
    func observeSystemMessage() -> PublishSubject<Target>
    func disconnectService()
}


class SystemSignalRUseCaseImpl: SystemSignalRUseCase {
    
    var systemRepo : SystemSignalRepository!
    
    init(_ systemRepo : SystemSignalRepository) {
        self.systemRepo = systemRepo
    }
    
    func observeSystemMessage() -> PublishSubject<Target> {
        systemRepo.connectService()
        systemRepo.subscribeEvent(target: Target.Kickout(nil))
        return systemRepo.observeSystemMessage()
    }
    
    func disconnectService() {
        systemRepo.disconnectService()
    }
}
