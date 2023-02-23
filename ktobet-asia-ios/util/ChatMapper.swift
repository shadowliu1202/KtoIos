import Foundation
import RxSwift
import SharedBu

class ChatMapper {
  static func mapTo(speakingAsyncBean: SpeakingAsyncBean, httpClient: HttpClient) throws -> ChatMessage.Message {
    let type = EnumMapper.convert(speakerType: speakingAsyncBean.speakerType)
    return ChatMessage.Message(
      id: speakingAsyncBean.messageId,
      speaker: convertSpeaker(speaker: speakingAsyncBean.speaker, speakerType: type),
      message: mapTo(
        speakingAsyncBean: speakingAsyncBean.message,
        speakerType: type,
        httpClient: httpClient),
      createTimeTick: try speakingAsyncBean.createdDate.toLocalDateTime())
  }

  private static func convertSpeaker(speaker: String, speakerType: SpeakerType) -> PortalChatRoom.Speaker {
    switch speakerType {
    case .player:
      return PortalChatRoom.SpeakerPlayer(name: speaker)
    case .handler:
      return PortalChatRoom.SpeakerHandler(name: speaker)
    case .system:
      return PortalChatRoom.SpeakerSystem(name: speaker)
    default:
      fatalError()
    }
  }

  private static func mapTo(
    speakingAsyncBean: Message,
    speakerType _: SpeakerType,
    httpClient: HttpClient) -> [ChatMessage.Content]
  {
    speakingAsyncBean.quillDeltas.map { it in
      if let image = it.attributes?.image {
        return ChatMessage
          .ContentImage(image: PortalImage.ChatImage(host: httpClient.host.absoluteString, path: image, isInChat: true))
      }

      if let link = it.attributes?.link {
        return ChatMessage.ContentLink(content: link)
      }

      return ChatMessage.ContentText(content: it.insert ?? "", attributes: it.attributes?.convert())
    }
  }
}
