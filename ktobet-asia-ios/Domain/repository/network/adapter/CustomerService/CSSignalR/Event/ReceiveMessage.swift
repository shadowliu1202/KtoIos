import Foundation
import RxSwift
import sharedbu

class ReceiveMessage: ChatRoomVisitor {
  let bean: SpeakingAsyncBean
  
  init(bean: SpeakingAsyncBean) {
    self.bean = bean
  }
  
  func visit(config _: Config) {
    // Do nothing
  }
  
  func visit(connection _: sharedbu.Connection) {
    // Do nothing
  }
  
  func visit(messageManager: MessageManager) {
    do {
      messageManager.update(unReadMessage: try ChatMapper.convert(bean: bean))
    }
    catch {
      Logger.shared.error(error)
    }
  }
  
  private func convert(speaker: String, speakerType: Int32) -> ChatMessage_.Speaker {
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

  private func convert(message: Message) -> [ChatMessage_.Content] {
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
