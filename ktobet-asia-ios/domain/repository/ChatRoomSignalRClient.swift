import Alamofire
import Foundation
import Moya
import RxSwift
import SharedBu

extension ChatRoomSignalRClient: HubConnectionDelegate {
  func connectionDidOpen(hubConnection _: HubConnection) { }

  func connectionDidFailToOpen(error: Error) {
    Logger.shared.error(error)
  }

  func connectionWillReconnect(error: Error) {
    Logger.shared.error(error)

    subscription?.dispose()

    subscription = customerInfraService.isPlayerInChat()
      .asObservable()
      .retry(.delayed(maxCount: 180, time: 1))
      .subscribe(onNext: { [weak self] in
        self?.refreshChatRoomState($0)
        self?.subscription?.dispose()
      })
  }

  func connectionDidClose(error: Error?) {
    guard let error else { return }
    Logger.shared.error(error)
  }
}

class ChatRoomSignalRClient: PortalChatRoomChatService {
  private(set) var token: String
  private var roomId: String
  private var skillId: String
  private var repository: CustomServiceRepository
  private var customerInfraService: CustomerInfraService
  private let httpClient: HttpClient
  private let disposeBag = DisposeBag()
  private var socketConnect: HubConnection?
  private var onMessage: ((PortalChatRoom.ChatAction) -> Void)?

  private var subscription: Disposable?

  init(
    token: String,
    skillId: String,
    roomId: String,
    repository: CustomServiceRepository,
    customerInfraService: CustomerInfraService,
    httpClient: HttpClient)
  {
    self.token = token
    self.skillId = skillId
    self.roomId = roomId
    self.repository = repository
    self.customerInfraService = customerInfraService
    self.httpClient = httpClient
  }

  convenience init(
    token: String,
    repository: CustomServiceRepository,
    customerInfraService: CustomerInfraService,
    httpClient: HttpClient)
  {
    self.init(
      token: token,
      skillId: "",
      roomId: "",
      repository: repository,
      customerInfraService: customerInfraService,
      httpClient: httpClient)
  }

  func close(roomId: String, onFinished: @escaping () -> Void) {
    repository.closeChatRoom(roomId: roomId)
      .andThen(repository.removeToken())
      .andThen(serviceDisconnect())
      .subscribe(onCompleted: {
        onFinished()
      }, onError: {
        Logger.shared.debug($0.localizedDescription)
        onFinished()
      })
      .disposed(by: disposeBag)
  }

  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }

  func getHistory(roomId: String) -> LoadingStatus<NSArray> {
    var messages: NSArray?
    do {
      if isPlayerInChat() {
        messages = try getInProcessChatMessageHistory()
      }
      else {
        messages = try getChatHistory(roomId)
      }
    }
    catch {
      Logger.shared.debug("ChatRoomSignalRClient, Please Check Date Format Return By API")
    }

    let status: Status = messages != nil ? .success : .failed
    return LoadingStatus(status: status, data: messages, message: "")
  }

  private func isPlayerInChat() -> Bool {
    if let roomId = getPlayerInChat()?.roomId, roomId.isNotEmpty {
      return true
    }
    return false
  }

  private func getInProcessChatMessageHistory() throws -> NSArray? {
    let group = DispatchGroup()
    group.enter()
    var decodedObject: [InProcessBean]!
    let url = URL(string: httpClient.host.absoluteString + "onlinechat/api/room/in-process")!
    let task = URLSession.shared.dataTask(with: url) { data, _, _ in
      guard let data else { return }
      decodedObject = try? JSONDecoder().decode(ResponseData<[InProcessBean]>.self, from: data).data
      group.leave()
    }

    task.resume()

    group.wait()
    if let object = decodedObject {
      let messages = try object.map {
        ChatMessage.Message(
          id: $0.messageId,
          speaker: self.repository.convertSpeaker(speaker: $0.speaker, speakerType: $0.speakerType),
          message: self.repository.covertContentFromInProcess(
            message: $0.message,
            speakerType: EnumMapper.convert(speakerType: $0.speakerType)),
          createTimeTick: try $0.createdDate.toLocalDateTime())
      } as NSArray
      return messages
    }
    else {
      return nil
    }
  }

  private func getChatHistory(_ roomId: String) throws -> NSArray? {
    let group = DispatchGroup()
    group.enter()
    var decodedObject: [RoomHistory]!
    let url = URL(string: httpClient.host.absoluteString + "api/room/record/\(roomId)")!
    let task = URLSession.shared.dataTask(with: url) { data, _, _ in
      guard let data else { return }
      decodedObject = try? JSONDecoder().decode(ResponseData<ChatHistoryBean>.self, from: data).data?.roomHistories
      group.leave()
    }

    task.resume()

    group.wait()
    if let object = decodedObject {
      let messages = try object.map {
        ChatMessage.Message(
          id: $0.messageId,
          speaker: self.repository.convertSpeaker(speaker: $0.speaker, speakerType: $0.speakerType),
          message: self.repository.covertContentFromInProcess(
            message: $0.message,
            speakerType: EnumMapper.convert(speakerType: $0.speakerType)),
          createTimeTick: try $0.createdDate.toLocalDateTime())
      } as NSArray
      return messages
    }
    else {
      return nil
    }
  }

  func receive(action: @escaping (PortalChatRoom.ChatAction) -> Void) {
    onMessage = action
  }

  func send(roomId: String, image: UploadImageDetail, onError: @escaping (KotlinThrowable) -> Void) {
    repository.send(image.portalImage.imageId, imageName: image.fileName, roomId: roomId)
      .subscribe(onError: { error in onError(KotlinThrowable(message: error.localizedDescription)) })
      .disposed(by: disposeBag)
  }

  func send(roomId: String, message: String, onError: @escaping (KotlinThrowable) -> Void) {
    repository.send(message, roomId: roomId).subscribe {
    } onError: { error in
      Logger.shared.debug(error.localizedDescription)
      onError(ExceptionFactory.create(error))
    }.disposed(by: disposeBag)
  }

  func start(isReconnect: Bool) {
    self.socketConnect?.stop()
    self.socketConnect = nil

    if
      let url = URL(
        string: httpClient.host.absoluteString
          .replacingOccurrences(of: "\(Configuration.internetProtocol)", with: "wss://") + "chat-ws?access_token=" + token)
    {
      self.socketConnect = HubConnectionBuilder(url: url)
        .withJSONHubProtocol()
        .withHttpConnectionOptions(configureHttpOptions: { option in
          option.skipNegotiation = true
        })
        .withLogging(minLogLevel: .debug)
        .withAutoReconnect()
        .withHubConnectionDelegate(delegate: self)
        .build()

      self.socketConnect!.start()
      subscribeHub()
      if isReconnect {
        onMessage?(PortalChatRoom.ChatActionRefresh())
      }

      if !self.roomId.isEmpty {
        if let object = getQueueNumber() {
          onMessage?(PortalChatRoom.ChatActionInitChatRoom(roomId: self.roomId, skillId: self.skillId, queue: object))
        }
      }
      else {
        if let number = getQueueNumber(), let bean = getPlayerInChat(), bean.roomId.isNotEmpty {
          onMessage?(PortalChatRoom.ChatActionInitChatRoom(roomId: bean.roomId, skillId: bean.skillId, queue: number))
        }
      }
    }
  }

  private func getQueueNumber() -> Int32? {
    let group = DispatchGroup()
    group.enter()
    var decodedObject: Int32?
    let url = URL(string: httpClient.host.absoluteString + "onlinechat/api/room/queue-number")!
    let task = URLSession.shared.dataTask(with: url) { data, _, _ in
      guard let data else { return }
      decodedObject = try? JSONDecoder().decode(ResponseData<Int32>.self, from: data).data
      group.leave()
    }

    task.resume()

    group.wait()

    return decodedObject
  }

  private func refreshChatRoomState(_ bean: PlayerInChatBean) {
    if bean.token.isNotEmpty {
      skillId = bean.skillId
      roomId = bean.roomId
      start(isReconnect: true)
    }
    else {
      refreshAndDisconnect()
    }
  }

  private func refreshAndDisconnect() {
    onMessage?(PortalChatRoom.ChatActionRefresh())
    onMessage?(PortalChatRoom.ChatActionClose())
  }

  private func getPlayerInChat() -> PlayerInChatBean? {
    let group = DispatchGroup()
    group.enter()
    var decodedObject: PlayerInChatBean?
    let url = URL(string: httpClient.host.absoluteString + "onlinechat/api/room/player/in-chat")!
    let task = URLSession.shared.dataTask(with: url) { data, _, _ in
      guard let data else { return }
      decodedObject = try? JSONDecoder().decode(ResponseData<PlayerInChatBean>.self, from: data).data
      group.leave()
    }
    task.resume()

    group.wait()

    return decodedObject
  }

  private func subscribeHub() {
    self.socketConnect?.on(method: Target.QueueNumberAsync.rawValue, callback: {
      self.onMessage?(PortalChatRoom.ChatActionWaiting())
    })

    self.socketConnect?.on(method: Target.UserJoinAsync.rawValue, callback: {
      self.onMessage?(PortalChatRoom.ChatActionCSAnswer())
    })

    self.socketConnect?.on(method: Target.SpeakingAsync.rawValue, callback: { [unowned self] (bean: SpeakingAsyncBean) in
      do {
        self
          .onMessage?(
            PortalChatRoom
              .ChatActionMessage(message: try ChatMapper.mapTo(speakingAsyncBean: bean, httpClient: self.httpClient)))
      }
      catch {
        print("ChatRoomSignalRClient, Please Check Date Format Return By API")
      }
    })

    self.socketConnect?.on(method: Target.StopRoomAsync.rawValue, callback: { [weak self] (_: String) in
      self?.onMessage?(PortalChatRoom.ChatActionClose())
    })

    self.socketConnect?.on(method: Target.MaintenanceAsync.rawValue, callback: { [weak self] _ in
      self?.onMessage?(PortalChatRoom.ChatActionMaintenance())
    })
  }

  private func serviceDisconnect() -> Completable {
    Completable.create { completable in
      self.disconnect()
      completable(.completed)
      return Disposables.create { }
    }
  }

  func disconnect() {
    self.socketConnect?.stop()
    self.socketConnect = nil
  }

  private enum Target: String {
    case UserJoinAsync
    case SpeakingAsync
    case QueueNumberAsync
    case StopRoomAsync
    case MaintenanceAsync
  }
}

struct SpeakingAsyncBean: Codable {
  let createdDate: String
  let message: Message
  let messageId: Int32
  let messageType: Int
  let playerRead: Bool
  let roomId: String
  let speaker: String
  let speakerId: String
  let speakerType: Int32
  let text: String
}

class NSURLSessionPinningDelegate: NSObject, URLSessionDelegate {
  private var httpClient: HttpClient

  init(httpClient: HttpClient) {
    self.httpClient = httpClient
  }

  func urlSession(
    _: URLSession,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
  {
    if challenge.protectionSpace.host == self.httpClient.host.absoluteString {
      completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    else {
      completionHandler(.performDefaultHandling, nil)
    }
  }
}
