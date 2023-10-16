import Foundation
import RxSwift
import sharedbu

class ChatMapper {
  private static let dateTimeMapper = DateTimeMapper()
  
  static func convert(beans: [InProcessBean]) throws -> [ChatMessage_.Message] {
    beans.map { bean in
      ChatMessage_.Message(
        id: bean.messageId,
        speaker: convert(speaker: bean.speaker, speakerType: bean.speakerType),
        message: convert(message: bean.message),
        createTimeTick: dateTimeMapper.toInstant(isoString: bean.createdDate),
        isProcessing: false)
    }
  }
  
  static func convert(bean: SpeakingAsyncBean) throws -> ChatMessage_.Message {
    ChatMessage_.Message(
      id: bean.messageId,
      speaker: convert(speaker: bean.speaker, speakerType: bean.speakerType),
      message: convert(message: bean.message),
      createTimeTick: dateTimeMapper.toInstant(isoString: bean.createdDate),
      isProcessing: false)
  }
  
  private static func convert(speaker: String, speakerType: Int32) -> ChatMessage_.Speaker {
    let speakerType = EnumMapper.convert(speakerType: speakerType)
    switch speakerType {
    case .player:
      return ChatMessage_.SpeakerPlayer(name: speaker)
    case .handler:
      return ChatMessage_.SpeakerHandler(name: speaker)
    case .system:
      return ChatMessage_.SpeakerSystem(name: speaker)
    default:
      fatalError("should not be here")
    }
  }

  private static func convert(message: Message) -> [ChatMessage_.Content] {
    message.quillDeltas.map {
      let attributes = $0.attributes
      if let image = attributes?.image {
        return ChatMessage_.ContentImage(image: ChatImage(path: image, inChat: true))
      }
      else if let link = attributes?.link {
        return ChatMessage_.ContentLink(content: link)
      }
      else {
        return ChatMessage_.ContentText(content: $0.insert, attributes: attributes?.convert())
      }
    }
  }
}
