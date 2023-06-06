import Foundation
import RxCocoa
import RxSwift
import SharedBu

class CustomerServiceViewModel {
  private var customerServiceUseCase: CustomerServiceUseCase!

  var uploadImageDetail: [Int: UploadImageDetail] = [:]
  var screenSizeOption = BehaviorRelay<ChatRoomScreen>(value: .Minimize)

  init(customerServiceUseCase: CustomerServiceUseCase) {
    self.customerServiceUseCase = customerServiceUseCase
  }

  lazy var chatMaintenanceStatus = customerServiceUseCase.currentChatRoom()
    .flatMapLatest { room in
      Observable<KotlinBoolean>.create { observer -> Disposable in
        room.setMaintenanceListener(callback: observer.onNext)
        return Disposables.create()
      }
    }
    .catchAndReturn(false)

  lazy var chatRoomMessage = customerServiceUseCase.currentChatRoom()
    .flatMapLatest { room in
      Observable<[ChatMessage]>.create { observer -> Disposable in
        room.setMessageListener(callback: observer.onNext)
        return Disposables.create()
      }
    }
    .catchAndReturn([])

  lazy var chatRoomUnreadMessage = customerServiceUseCase.currentChatRoom()
    .flatMapLatest { room in
      Observable<[ChatMessage]>.create { observer -> Disposable in
        room.setUnreadMessageListener(callback: observer.onNext)
        return Disposables.create()
      }
    }
    .catchAndReturn([])

  lazy var preLoadChatRoomStatus = customerServiceUseCase.currentChatRoom()
    .flatMapLatest { room in
      Observable<PortalChatRoom.ConnectStatus>.create { observer -> Disposable in
        room.setStatusListener(callback: observer.onNext)
        return Disposables.create()
      }
    }
    .catchAndReturn(PortalChatRoom.ConnectStatus.notexist)
    .distinctUntilChanged()

  lazy var currentQueueNumber = customerServiceUseCase.currentChatRoom()
    .flatMapLatest { room in
      Observable<KotlinInt>.create { observer -> Disposable in
        room.setNumberInLineListener(callback: observer.onNext)
        return Disposables.create()
      }
    }
    .catchAndReturn(0)

  private var surveyAnswers: SurveyAnswers?
  func connectChatRoom(survey: Survey?) -> Observable<PortalChatRoom.ConnectStatus> {
    findChatRoom().asObservable().flatMap { room -> Single<PortalChatRoom> in
      if room == CustomServiceRepositoryImpl.PortalChatRoomNoExist {
        return self.customerServiceUseCase.createChatRoom(survey: survey!, surveyAnswers: self.surveyAnswers)
      }
      else {
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
    customerServiceUseCase.checkServiceAvailable()
  }

  func closeChatRoom() -> Completable {
    findChatRoom().flatMapCompletable { chatRoom -> Completable in
      Completable.create { event -> Disposable in
        if chatRoom == CustomServiceRepositoryImpl.PortalChatRoomNoExist {
          event(.completed)
        }
        else {
          DispatchQueue.main.async {
            chatRoom.leaveChatRoom(onFinished: {
              event(.completed)
            })
          }
        }

        return Disposables.create { }
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
      chatRoom.send(message: message, onError: { apiException in
        completeble(.error(apiException))
      })

      return Disposables.create { }
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
      return Disposables.create { }
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
        return Disposables.create { }
      }
    }
  }

  func fullscreen() -> Completable {
    screenSizeOption.accept(.Fullscreen)
    return findChatRoom().flatMapCompletable { chatRoom in
      Completable.create { completeble in
        chatRoom.setFocus(isFocus: true)
        completeble(.completed)
        return Disposables.create { }
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
        return Disposables.create { }
      }
    }
  }

  private func findChatRoom() -> Single<PortalChatRoom> {
    customerServiceUseCase.currentChatRoom().first().map { $0! }
  }

  func findCurrentRoomId() -> Single<RoomId> {
    findChatRoom()
      .flatMap { [weak self] room -> Single<RoomId> in
        guard let self
        else {
          return .error(KTOError.LostReference)
        }

        return self.waitRoomId(portalChatRoom: room)
      }
  }

  private func waitRoomId(portalChatRoom: PortalChatRoom) -> Single<RoomId> {
    Single.create { single in
      portalChatRoom.setRoomIdListener { roomId in
        single(.success(roomId))
      }

      return Disposables.create()
    }
  }

  private func waitSkillId(portalChatRoom: PortalChatRoom) -> Single<RoomId> {
    Single.create { single in
      portalChatRoom.setSkillIdListener { skillId in
        single(.success(skillId))
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

  func setupSurveyAnswer(answers: SurveyAnswers?) {
    surveyAnswers = answers
  }
}

enum ChatRoomScreen { case Fullscreen, Minimize }
