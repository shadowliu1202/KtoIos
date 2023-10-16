import sharedbu

@available(*, deprecated, message: "should be removed after ui refactor")
class ChatRoomTempMapper {
  @Injected private var httpClient: HttpClient
  @Injected private var playerConfiguration: PlayerConfiguration
  
  func convertToStatus(_ chatRoomDTO: CustomerServiceDTO.ChatRoom) -> PortalChatRoom.ConnectStatus {
    switch chatRoomDTO.status {
    case let status as sharedbu.Connection.StatusNotExist:
      return .notexist
    case let status as sharedbu.Connection.StatusConnected:
      return .connected
    case let status as sharedbu.Connection.StatusConnecting:
      return .connecting
    case let status as sharedbu.Connection.StatusClose:
      return .closed
    default:
      fatalError("should not reach here.")
    }
  }
  
  func convertToReadMessages(_ chatRoomDTO: CustomerServiceDTO.ChatRoom) -> [ChatMessage] {
    convertMessages(chatRoomDTO.readMessage)
  }
  
  func convertToUnreadMessages(_ chatRoomDTO: CustomerServiceDTO.ChatRoom) -> [ChatMessage] {
    convertMessages(chatRoomDTO.unReadMessage)
  }
  
  func convertMessages(_ messages: [CustomerServiceDTO.ChatMessage]) -> [ChatMessage] {
    messages
      .enumerated()
      .map { index, DTO in
        .Message(
          id: Int32(index),
          speaker: convertToSpeaker(DTO),
          message: convertToContents(DTO),
          createTimeTick: DTO.createTime.toLocalDateTime(playerConfiguration.localeTimeZone()))
      }
  }
  
  private func convertToSpeaker(_ DTO: CustomerServiceDTO.ChatMessage) -> PortalChatRoom.Speaker {
    switch DTO.speaker.type {
    case .player:
      return PortalChatRoom.SpeakerPlayer(name: DTO.speaker.name)
    case .cs:
      return PortalChatRoom.SpeakerHandler(name: DTO.speaker.name)
    case .system:
      return PortalChatRoom.SpeakerSystem(name: DTO.speaker.name)
    default:
      fatalError("should not reach here.")
    }
  }
  
  private func convertToContents(_ DTO: CustomerServiceDTO.ChatMessage) -> [ChatMessage.Content] {
    DTO.contents.map(convertToContent)
  }

  private func convertToContent(_ content: CustomerServiceDTO.Content) -> ChatMessage.Content {
    switch content.type {
    case .text:
      return ChatMessage.ContentText(content: content.text, attributes: nil)
    case .image:
      return ChatMessage
        .ContentImage(image: .ChatImage(
          host: httpClient.host.absoluteString,
          path: content.image?.path() ?? "",
          isInChat: false))
    case .link:
      return ChatMessage.ContentLink(content: content.link)
    default:
      fatalError("should not reach here.")
    }
  }
  
  func convertToChatHistories(_ DTO: CustomerServiceDTO.ChatHistories) -> [ChatHistory] {
    DTO.histories
      .map {
        .init(
          createDate: $0.createDate.toLocalDateTime(playerConfiguration.localeTimeZone()),
          title: $0.title,
          roomId: $0.roomId)
      }
  }
  
  func convertToDTOChatHistoriesHistory(chatHistories: [ChatHistory]) -> [CustomerServiceDTO.ChatHistoriesHistory] {
    chatHistories.map {
      .init(
        createDate: $0.createDate.toInstant(timeZone: playerConfiguration.timezone()),
        title: $0.title,
        roomId: $0.roomId)
    }
  }
}

extension sharedbu.Instant {
  func toLocalDateTime(_ timeZone: Foundation.TimeZone) -> LocalDateTime {
    Date(timeIntervalSince1970: TimeInterval(Double(self.epochSeconds)))
      .toLocalDateTime(timeZone)
  }
}

extension sharedbu.Instant? {
  func toLocalDateTime(_ timeZone: Foundation.TimeZone) -> LocalDateTime {
    guard let self
    else {
      return Date().toLocalDateTime(timeZone)
    }
    
    return self.toLocalDateTime(timeZone)
  }
}
