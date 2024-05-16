import Combine
import sharedbu
import SwiftUI

struct ChatRoomView<ViewModel>: View
  where ViewModel:
  ChatRoomViewModelProtocol &
  ObservableObject
{
  @StateObject private var viewModel: ViewModel
  
  @State private var textFieldOnFocus = false
  
  private let textFieldCountLimit = 500
  
  private let onChatRoomClose: (String) -> Void
  private let onChatRoomMaintain: () -> Void
  private let onTapImage: (String) -> Void
  private let onTapCamera: () -> Void
  
  private let sizeChangePublisher = PassthroughSubject<Void, Never>()
  
  init(
    viewModel: ViewModel,
    onChatRoomClose: @escaping (String) -> Void,
    onChatRoomMaintain: @escaping () -> Void,
    onTapImage: @escaping ((String) -> Void),
    onTapCamera: @escaping (() -> Void))
  {
    self._viewModel = StateObject(wrappedValue: viewModel)
    self.onChatRoomClose = onChatRoomClose
    self.onChatRoomMaintain = onChatRoomMaintain
    self.onTapImage = onTapImage
    self.onTapCamera = onTapCamera
  }
  
  var sizeChangeReader: some View {
    GeometryReader { proxy in
      Color.clear
        .onChange(of: proxy.size) { _ in
          sizeChangePublisher.send(())
        }
    }
  }
  
  var body: some View {
    VStack(spacing: 0) {
      ChattingListView(
        messages: viewModel.messages,
        onTapImage: { url in
          hideKeyboardThenExcute {
            onTapImage(url)
          }
        })
        .onTapGesture {
          hideKeyboardThenExcute(nil)
        }
        
      InputView(
        textFieldOnFocus: $textFieldOnFocus,
        textFieldCountLimit: textFieldCountLimit,
        onTapCamera: {
          hideKeyboardThenExcute(onTapCamera)
        })
    }
    .overlay(sizeChangeReader)
    .backgroundColor(.greyScaleWhite, ignoresSafeArea: .bottom)
    .environmentObject(viewModel)
    .onViewDidLoad {
      viewModel.setup(
        onChatRoomClose: onChatRoomClose,
        onChatRoomMaintain: onChatRoomMaintain)
    }
    .onAppear {
      viewModel.readAllMessage(updateToLast: nil, isAuto: true)
    }
    .onDisappear {
      viewModel.readAllMessage(updateToLast: nil, isAuto: false)
    }
  }
  
  private func hideKeyboardThenExcute(_ action: (() -> Void)?) {
    Task { @MainActor in
      await hideKeyboard()
      action?()
    }
  }
  
  @MainActor
  private func hideKeyboard() async {
    guard textFieldOnFocus else { return }
    
    async let onComplete: Void? = sizeChangePublisher.eraseToAnyPublisher().valueWithoutError
    UIApplication.shared.hideKeyboard()
    await onComplete
  }
}

extension ChatRoomView {
  // MARK: - InputView
  
  struct InputView: View {
    @EnvironmentObject var viewModel: ViewModel
    
    @State private var text = ""
    @State private var textFieldHeight: CGFloat?
    
    @Binding var textFieldOnFocus: Bool
    
    private let textChangePublisher = PassthroughSubject<String, Never>()
    
    let textFieldCountLimit: Int
    let onTapCamera: (() -> Void)?
    
    var placeholder: some View {
      Text(viewModel.disableInputView ? Localize.string("customerservice_chat_ended") : "")
        .localized(weight: .regular, size: 16, color: .textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    var textFieldHeightReader: some View {
      GeometryReader { proxy in
        Color.clear
          .onViewDidLoad {
            textFieldHeight = proxy.size.height
          }
      }
    }
    
    var body: some View {
      HStack(alignment: .bottom, spacing: 8) {
        Button(
          action: {
            onTapCamera?()
          },
          label: {
            viewModel.disableInputView ? Image("Take Photo disable") : Image("Take Photo")
          })
          .frame(width: 32, height: 32)
        
        UIKitTextView(
          isInFocus: $textFieldOnFocus,
          text: $text,
          maxLength: textFieldCountLimit,
          initConfiguration: { uiTextField in
            uiTextField.font = UIFont(name: "PingFangSC-Regular", size: 16)
            uiTextField.tintColor = .primaryDefault
          })
          .frame(height: getTextFieldHeight())
          .overlay(textFieldHeightReader)
          .overlay(placeholder)
          .padding(.horizontal, 12)
          .padding(.vertical, 4)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .stroke(Color(UIColor.greyScaleBlack.withAlphaComponent(0.3)), lineWidth: 1))
          .localized(weight: .regular, size: 16, color: .greyScaleDefault)
        
        AsyncButton(
          label: {
            text.isEmpty ? Image("Send Message(Disable)") : Image("Send Message")
          },
          action: {
            viewModel.send(message: text)
            text = ""
          })
          .disabled(text.isEmpty)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .fixedSize(horizontal: false, vertical: true)
      .backgroundColor(.greyScaleWhite)
      .disabled(viewModel.disableInputView)
      .onChange(of: text) { newValue in
        textChangePublisher.send(newValue)
      }
      .onReceive(
        textChangePublisher
          .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main))
      {
        viewModel.sendPreview(message: $0)
      }
    }
    
    private func getTextFieldHeight() -> CGFloat? {
      guard let textFieldHeight else { return nil }
      
      return text.contains("\n") ? textFieldHeight * 2 : textFieldHeight
    }
  }
}

// MARK: - Preview

struct ChatRoomView_Previews: PreviewProvider {
  class FakeViewModel: ChatRoomViewModelProtocol, ObservableObject {
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
            image: nil)
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
            image: nil),
          .init(
            id: "1-1",
            type: .text,
            text: "实名验证要去哪里设定？",
            textAttributes: nil,
            image: nil),
        ],
        isProcessing: false),
      .unreadSeperator,
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
            image: nil),
          .init(
            id: "2-1",
            type: .text,
            text: "YT",
            textAttributes: .init(
              align: nil,
              background: nil,
              bold: nil,
              color: nil,
              font: nil,
              image: nil,
              italic: nil,
              link: "https://www.youtube.com",
              size: nil,
              underline: nil),
            image: nil)
        ],
        isProcessing: false)
    ]
    
    var disableInputView = false
     
    func setup(
      onChatRoomClose _: @escaping (String) -> Void,
      onChatRoomMaintain _: @escaping () -> Void) { }
    func send(message _: String) { }
    func sendPreview(message _: String) { }
    func readAllMessage(updateToLast _: Bool?, isAuto _: Bool?) { }
  }

  static var previews: some View {
    ChatRoomView(
      viewModel: FakeViewModel(),
      onChatRoomClose: { _ in },
      onChatRoomMaintain: { },
      onTapImage: { _ in },
      onTapCamera: { })
  }
}
