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
  
  private func convert(speaker: String, speakerType: Int32) -> ChatMessage.Speaker {
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

  private func convert(message: Message) -> [ChatMessage.Content] {
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
