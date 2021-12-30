import Foundation
import RxSwift
import RxCocoa
import SharedBu

class CustomerServiceViewModel {
    private var customerServiceUseCase: CustomerServiceUseCase!
    
    var uploadImageDetail: [Int: UploadImageDetail] = [:]
    var screenSizeOption = BehaviorRelay<ChatRoomScreen>(value: .Minimize)

    init(customerServiceUseCase: CustomerServiceUseCase) {
        self.customerServiceUseCase = customerServiceUseCase
    }
    
    lazy var chatRoomMessage = customerServiceUseCase.currentChatRoom()
        .flatMapLatest { room in
            Observable<[ChatMessage]>.create { observer -> Disposable in
                if room == CustomServiceRepositoryImpl.PortalChatRoomNoExist {
                    print("123")
                }
                
                room.setMessageListener(callback: observer.onNext)
                return Disposables.create()
            }
        }
        .catchErrorJustReturn([])
    
    lazy var chatRoomUnreadMessage = customerServiceUseCase.currentChatRoom()
        .flatMapLatest { room in
            Observable<[ChatMessage]>.create { observer -> Disposable in
                if room == CustomServiceRepositoryImpl.PortalChatRoomNoExist {
                    print("123")
                }
                
                room.setUnreadMessageListener(callback: observer.onNext)
                return Disposables.create()
            }
        }
        .catchErrorJustReturn([])
    
    lazy var preLoadChatRoomStatus = customerServiceUseCase.currentChatRoom()
        .flatMapLatest { room in
            return Observable<PortalChatRoom.ConnectStatus>.create { observer -> Disposable in
                room.setStatusListener(callback: observer.onNext)
                return Disposables.create()
            }
        }
        .catchErrorJustReturn(PortalChatRoom.ConnectStatus.notexist)
        .distinctUntilChanged()
    
    lazy var currentQueueNumber = customerServiceUseCase.currentChatRoom()
        .flatMapLatest { room in
            return Observable<KotlinInt>.create { observer -> Disposable in
                room.setNumberInLineListener(callback: observer.onNext)
                return Disposables.create()
            }
        }
        .catchErrorJustReturn(0)
    
//    func connectChatRoom(skillId: String?, connectId: String?) -> Observable<PortalChatRoom.ConnectStatus> {
//        let room = skillId == nil ? findChatRoom() : joinChatRoom(skillId: skillId!, connectId: connectId)
//        return room.asObservable().flatMap { r in
//            Observable<PortalChatRoom.ConnectStatus>.create { observer -> Disposable in
//                r.setStatusListener(callback: observer.onNext)
//                return Disposables.create()
//            }
//        }.distinctUntilChanged()
//    }
    
    private var surveyAnswers: SurveyAnswers? = nil
    func connectChatRoom(survey: Survey) -> Observable<PortalChatRoom.ConnectStatus> {
        findChatRoom().asObservable().flatMap { room -> Single<PortalChatRoom> in
            if room == CustomServiceRepositoryImpl.PortalChatRoomNoExist {
                return self.customerServiceUseCase.createChatRoom(survey: survey, surveyAnswers: self.surveyAnswers)
            } else {
                return Single.just(room)
            }
        }.flatMap { room in
            Observable<PortalChatRoom.ConnectStatus>.create { observer -> Disposable in
                room.setStatusListener(callback: observer.onNext)
                return Disposables.create()
            }
        }.distinctUntilChanged()
    }
    
    func checkServiceAvailable() -> Single<Bool> {
        return customerServiceUseCase.checkServiceAvailable()
    }
    
    func closeChatRoom() -> Completable {
        findChatRoom().flatMapCompletable { chatRoom in
            Completable.create { completable in
                if chatRoom == CustomServiceRepositoryImpl.PortalChatRoomNoExist {
                    print("123123")
                }
                chatRoom.leaveChatRoom()
                completable(.completed)
                return Disposables.create()
            }
        }
    }
    
    func send(message: String) -> Completable {
        findChatRoom().flatMapCompletable { chatRoom in
            self.send(message: message, chatRoom: chatRoom)
        }
    }
    
    private func send(message: String, chatRoom: PortalChatRoom) -> Completable {
        Completable.create { completeble in
            chatRoom.send(message: message, onError: { throwable in
                completeble(.error(throwable.asError()))
            })
            
            completeble(.completed)
            return Disposables.create {}
        }
    }
    
    func send(image: UploadImageDetail) -> Completable {
        findChatRoom().flatMapCompletable { chatRoom in
            self.send(image: image, chatRoom: chatRoom)
        }
    }
    
    private func send(image: UploadImageDetail, chatRoom: PortalChatRoom) -> Completable {
        Completable.create { completeble in
            chatRoom.send(imageDetail: image) { throwable in
                completeble(.error(throwable.asError()))
            }
            
            completeble(.completed)
            return Disposables.create {}
        }
    }
    
    func searchChatRoom() -> Single<PortalChatRoom> {
        customerServiceUseCase.searchChatRoom()
    }
    
    func minimize() -> Completable {
        screenSizeOption.accept(.Minimize)
        return findChatRoom().flatMapCompletable { chatRoom in
            Completable.create { completeble in
                chatRoom.setFocus(isFocus: false)
                completeble(.completed)
                return Disposables.create {}
            }
        }
    }
    
    func fullscreen() -> Completable {
        screenSizeOption.accept(.Fullscreen)
        return findChatRoom().flatMapCompletable { chatRoom in
            Completable.create { completeble in
                chatRoom.setFocus(isFocus: true)
                completeble(.completed)
                return Disposables.create {}
            }
        }
    }
    
    func markAllRead() -> Completable {
        findChatRoom().flatMapCompletable { chatRoom in
            Completable.create { completeble in
                if self.screenSizeOption.value == .Fullscreen {
                    chatRoom.markAllRead()
                }
                completeble(.completed)
                return Disposables.create {}
            }
        }
    }
    
    private func findChatRoom() -> Single<PortalChatRoom> {
        customerServiceUseCase.currentChatRoom().first().map { $0! }
    }
    
//    private func joinChatRoom(skillId: String, connectId: String?) -> Single<PortalChatRoom> {
//        if connectId == nil {
//            return customerServiceUseCase.createChatRoom(csSkillId: skillId)
//        } else {
//            return customerServiceUseCase.createChatRoom(csSkillId: skillId)
//                .flatMap { room in
//                    self.waitRoomId(portalChatRoom: room).flatMapCompletable { roomId in
//                        self.customerServiceUseCase.bindChatRoomWithSurvey(roomId: roomId, connectId: connectId!)
//                    }
//                    .andThen(Single.just(room))
//                }
//        }
//    }
    
    func findCurrentRoomId() -> Single<RoomId> {
        findChatRoom().flatMap(waitRoomId)
    }
    
    private func waitRoomId(portalChatRoom: PortalChatRoom) -> Single<RoomId> {
        Single.create { single in
            if portalChatRoom == CustomServiceRepositoryImpl.PortalChatRoomNoExist {
                print("123")
            }
            portalChatRoom.setRoomIdListener { roomId in
                single(.success(roomId))
            }
            
            return Disposables.create()
        }
    }
    
    func uploadImage(imageData: Data) -> Single<UploadImageDetail> {
        customerServiceUseCase.uploadImage(imageData: imageData)
    }
    
    func getBelongedSkillId(platform: Int) -> Single<String> {
        customerServiceUseCase.getBelongedSkillId(platform: platform)
    }
}

enum ChatRoomScreen { case Fullscreen, Minimize }
