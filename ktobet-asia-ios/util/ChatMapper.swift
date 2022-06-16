import Foundation
import RxSwift
import SharedBu


class ChatMapper {
    
    static private let localStorageRepo: PlayerLocaleConfiguration = DI.resolve(LocalStorageRepositoryImpl.self)!
    
    static func mapTo(speakingAsyncBean: SpeakingAsyncBean) throws -> ChatMessage.Message {
        let type = EnumMapper.convert(speakerType: speakingAsyncBean.speakerType)
        return ChatMessage.Message(id: speakingAsyncBean.messageId,
                                   speaker: convertSpeaker(speaker: speakingAsyncBean.speaker, speakerType: type),
                                   message: mapTo(speakingAsyncBean: speakingAsyncBean.message, speakerType: type),
                                   createTimeTick: try speakingAsyncBean.createdDate.toLocalDateTime())
    }
    
    private static func convertSpeaker(speaker: String, speakerType: SpeakerType) -> PortalChatRoom.Speaker {
        switch speakerType {
        case .player:
            return PortalChatRoom.SpeakerPlayer.init(name: speaker)
        case .handler:
            return PortalChatRoom.SpeakerHandler.init(name: speaker)
        case .system:
            return PortalChatRoom.SpeakerSystem.init(name: speaker)
        default:
            return PortalChatRoom.Speaker.init()
        }
    }
    
    private static func mapTo(speakingAsyncBean: Message, speakerType: SpeakerType) -> [ChatMessage.Content] {
        speakingAsyncBean.quillDeltas.map { it in
            if let image = it.attributes?.image {
                return ChatMessage.ContentImage.init(image: PortalImage.ChatImage.init(host: Configuration.host[localStorageRepo.getCultureCode()]!, path: image))
            }
            
            if let link = it.attributes?.link {
                return ChatMessage.ContentLink.init(content: link)
            }
            
            
            
            return ChatMessage.ContentText.init(content: it.insert ?? "", attributes: it.attributes?.convert())
        }
    }
}
