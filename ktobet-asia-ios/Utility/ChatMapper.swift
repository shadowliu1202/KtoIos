import Foundation
import RxSwift
import sharedbu

class ChatMapper {
  private static let dateTimeMapper = DateTimeMapper()
  
  static func convert(beans: [InProcessBean]) throws -> [ChatMessage.Message] {
    beans.map { bean in
      ChatMessage.Message(
        id: bean.messageId,
        speaker: convert(speaker: bean.speaker, speakerType: bean.speakerType),
        message: convert(message: bean.message),
        createTimeTick: dateTimeMapper.toInstant(isoString: bean.createdDate),
        isProcessing: false)
    }
  }
  
  static func convert(bean: SpeakingAsyncBean) throws -> ChatMessage.Message {
    ChatMessage.Message(
      id: bean.messageId,
      speaker: convert(speaker: bean.speaker, speakerType: bean.speakerType),
      message: convert(message: bean.message),
      createTimeTick: dateTimeMapper.toInstant(isoString: bean.createdDate),
      isProcessing: false)
  }
  
  private static func convert(speaker: String, speakerType: Int32) -> ChatMessage.Speaker {
    let speakerType = EnumMapper.convert(speakerType: speakerType)
    switch speakerType {
    case .player:
      return ChatMessage.SpeakerPlayer(name: speaker)
    case .handler:
      return ChatMessage.SpeakerHandler(name: speaker)
    case .system:
      return ChatMessage.SpeakerSystem(name: speaker)
    default:
      fatalError("should not be here")
    }
  }

  private static func convert(message: Message) -> [ChatMessage.Content] {
    message.quillDeltas.map {
      let attributes = $0.attributes
      if let image = attributes?.image {
        return ChatMessage.ContentImage(image: ChatImage(path: image, inChat: true))
      }
      else {
        return ChatMessage.ContentText(content: $0.insert, attributes: attributes?.convert())
      }
    }
  }
}
