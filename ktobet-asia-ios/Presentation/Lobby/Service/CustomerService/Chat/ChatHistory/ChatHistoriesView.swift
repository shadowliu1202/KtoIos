import sharedbu
import SwiftUI

struct ChatHistoriesView<ViewModel>: View
  where ViewModel:
  ChatHistoriesViewModelProtocol &
  ObservableObject
{
  @StateObject var viewModel: ViewModel
  
  var roomId: String
  var onTapImage: ((String) -> Void)?
  
  init(
    viewModel: ViewModel,
    roomId: String,
    onTapImage: ((String) -> Void)?)
  {
    self._viewModel = StateObject(wrappedValue: viewModel)
    self.roomId = roomId
    self.onTapImage = onTapImage
  }
  
  var body: some View {
    ChattingListView(
      messages: viewModel.messages,
      enableScrollAnimation: false,
      onTapImage: { path in
        onTapImage?(path)
      })
      .overlay(
        VStack {
          if viewModel.messages.isEmpty {
            SwiftUILoadingView()
          }
        })
      .onViewDidLoad {
        viewModel.setup(roomId: roomId)
      }
  }
}

struct ChatHistoriesView_Previews: PreviewProvider {
  class FakeViewModel: ChatHistoriesViewModelProtocol, ObservableObject {
    var messages: [CustomerServiceDTO.ChatMessage] = [
      .init(
        id: "0",
        speaker: .init(
          type: .system,
          name: "system"),
        createTime: ClockSystem().now(),
        contents: [
          .init(
            id: "0-0",
            type: .text,
            text: "您本次的聊天编号为2102260022。\n您好，客服JOY将为您提供服务。",
            textAttributes: nil,
            image: nil,
            link: "")
        ],
        isProcessing: false),
      .init(
        id: "1",
        speaker: .init(
          type: .player,
          name: "player"),
        createTime: ClockSystem().now(),
        contents: [
          .init(
            id: "1-0",
            type: .text,
            text: "提款是否一定需要经过实名验证？",
            textAttributes: nil,
            image: nil,
            link: ""),
          .init(
            id: "1-1",
            type: .text,
            text: "实名验证要去哪里设定？",
            textAttributes: nil,
            image: nil,
            link: ""),
        ],
        isProcessing: false),
      .init(
        id: "2",
        speaker: .init(
          type: .cs,
          name: "cs"),
        createTime: ClockSystem().now(),
        contents: [
          .init(
            id: "2-0",
            type: .text,
            text: "是的，这是为了防治洗钱以及用户安全性问题。",
            textAttributes: nil,
            image: nil,
            link: ""),
          .init(
            id: "2-1",
            type: .link,
            text: "YT",
            textAttributes: nil,
            image: nil,
            link: "https://www.youtube.com")
        ],
        isProcessing: false),
      .init(
        id: "3",
        speaker: .init(
          type: .cs,
          name: "cs"),
        createTime: ClockSystem().now(),
        contents: [
          .init(
            id: "3-0",
            type: .text,
            text: "您可以在个人资料选单中找到。",
            textAttributes: nil,
            image: nil,
            link: "")
        ],
        isProcessing: false),
      .init(
        id: "4",
        speaker: .init(
          type: .player,
          name: "cs"),
        createTime: ClockSystem().now(),
        contents: [
          .init(
            id: "4-0",
            type: .text,
            text: "所以我要关闭对话视窗后，再从右上角的选单选择吗？",
            textAttributes: nil,
            image: nil,
            link: "")
        ],
        isProcessing: false)
    ]
    
    func setup(roomId _: String) { }
  }

  static var previews: some View {
    ChatHistoriesView(
      viewModel: FakeViewModel(),
      roomId: "",
      onTapImage: { _ in })
  }
}
