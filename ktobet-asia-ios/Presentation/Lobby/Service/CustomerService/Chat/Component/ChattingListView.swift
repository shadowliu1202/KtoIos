import Combine
import sharedbu
import SwiftUI

extension CustomerServiceDTO.Content {
    func toWrapContent() -> ChattingListView.WrapContent {
        let type: ChattingListView.CompositeContent.ContentType
    
        if image != nil {
            type = .image
        }
        else if
            let attributes = textAttributes,
            attributes.link != nil
        {
            type = .link
        }
        else {
            type = .text
        }
    
        return ChattingListView.WrapContent(type: type, content: self)
    }
}

extension ChattingListView {
    // FIXME: Refactor after SwiftUI3
    struct WrapContent {
        let type: CompositeContent.ContentType
        let content: CustomerServiceDTO.Content
    }
  
    struct CompositeContent: Identifiable {
        enum ContentType {
            case text
            case image
            case link
        }
    
        let id: String
        let type: ContentType
        let contents: [CustomerServiceDTO.Content]
    }
}

private func groupSameType(of contents: [CustomerServiceDTO.Content]) -> [ChattingListView.CompositeContent] {
    var partialResult: [ChattingListView.CompositeContent] = []
    var tempGroup: [ChattingListView.WrapContent] = []

    let contents = contents.map { $0.toWrapContent() }
  
    for content in contents {
        if let first = tempGroup.first {
            if first.type == content.type {
                tempGroup.append(content)
            }
            else {
                partialResult.append(ChattingListView.CompositeContent(
                    id: first.content.id,
                    type: first.type,
                    contents: tempGroup.map { $0.content }))
                tempGroup = [content]
            }
        }
        else {
            tempGroup = [content]
        }
    }

    if let first = tempGroup.first {
        partialResult.append(ChattingListView.CompositeContent(
            id: first.content.id,
            type: first.type,
            contents: tempGroup.map { $0.content }))
    }

    return partialResult
}

extension ChattingListView {
    enum TestTag: String {
        case text
        case image
        case link
        case separator
    }
}

extension CustomerServiceDTO.ChatMessage {
    static let unreadSeperator = CustomerServiceDTO.ChatMessage(
        id: "-1",
        speaker: CustomerServiceDTO.Speaker(type: .system, name: ""),
        createTime: nil,
        contents: [],
        isProcessing: false)
}

struct ChattingListView: View {
    @StateObject private var viewModel: ChattingListViewModel = Injectable.resolveWrapper(ChattingListViewModel.self)
  
    private let messages: [CustomerServiceDTO.ChatMessage]
    private let onTapImage: ((String) -> Void)?
  
    init(
        messages: [CustomerServiceDTO.ChatMessage],
        onTapImage: ((String) -> Void)? = nil)
    {
        self.messages = messages
        self.onTapImage = onTapImage
    }
  
    var body: some View {
        GeometryReader { geometryProxy in
            let bubbleMaxWidth = geometryProxy.size.width * 0.7
      
            ScrollViewReader { readerProxy in
                ScrollView(showsIndicators: false) {
                    PageContainer(bottomPadding: 0) {
                        LazyVStack(spacing: 12) {
                            ForEach(messages, id: \.id) { message in
                                VStack(spacing: 0) {
                                    if message == CustomerServiceDTO.ChatMessage.unreadSeperator {
                                        UnreadSeperator()
                                    }
                                    else {
                                        switch message.speaker.type {
                                        case .cs,
                                             .player:
                                            ConversationCell(
                                                message: message,
                                                maxWidth: bubbleMaxWidth,
                                                onTapImage: onTapImage)
                      
                                        case .system:
                                            SystemInfoCell(
                                                message: message,
                                                showTopSeparator: isLastAndPreviousNotSystem(message),
                                                showBottomSeparator: message != messages.last || message == messages.first)
                                        }
                                    }
                                }
                                .id(message.id)
                            }
              
                            ChatContensBottomPosition()
                        }
                    }
                    .padding(.horizontal, 30)
                }
                .environmentObject(viewModel)
                .onViewDidLoad {
                    viewModel.downloadImages(messages)
                }
                .onChange(of: messages) { newValue in
                    viewModel.downloadImages(newValue)
                }
                .onViewDidLoad {
                    withAnimation { readerProxy.scrollTo(ChatContensBottomPosition.id) }
                }
                .onChange(of: messages) { _ in
                    withAnimation { readerProxy.scrollTo(ChatContensBottomPosition.id) }
                }
            }
        }
        .backgroundColor(.greyScaleChatWindow)
    }
  
    private func isLastAndPreviousNotSystem(_ message: CustomerServiceDTO.ChatMessage) -> Bool {
        guard message != messages.first, message == messages.last else { return false }
    
        if
            let index = messages.firstIndex(of: message),
            index - 1 >= 0
        {
            switch messages[index - 1].speaker.type {
            case .cs,
                 .player:
                return true
            case .system:
                return false
            }
        }
        else {
            return true
        }
    }
}
 
extension ChattingListView {
    // MARK: - UnreadSeperator
  
    struct UnreadSeperator: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 24) {
                Text(key: "customerservice_chat_room_unread_below")
                    .localized(weight: .regular, size: 12, color: .greyScaleWhite)
        
                Separator(color: .textPrimary, lineWidth: 0.5)
            }
        }
    }
  
    // MARK: - ConversationCell
  
    struct ConversationCell: View {
        let message: CustomerServiceDTO.ChatMessage
        let maxWidth: CGFloat
        let onTapImage: ((String) -> Void)?
    
        var body: some View {
            let alignment = getAlignment()
            VStack(alignment: alignment.horizontal, spacing: 4) {
                Text(message.createTime?.toTimeString() ?? "")
                    .localized(weight: .regular, size: 12, color: .textPrimary)
        
                ChattingListView.BubbleBackground(speakerType: message.speaker.type) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(groupSameType(of: message.contents), id: \.id) { compositeContent in
                            switch compositeContent.type {
                            case .text:
                                ChattingListView.TextContent(compositeContent)
                                    .localized(weight: .regular, size: 14, color: .greyScaleDefault)
                
                            case .image:
                                ChattingListView.ImageContent(
                                    compositeContent: compositeContent,
                                    onTapImage: onTapImage)
                
                            case .link:
                                ChattingListView.LinkContent(compositeContent)
                            }
                        }
                    }
                }
                .frame(maxWidth: maxWidth, alignment: alignment)
                .frame(maxWidth: .infinity, alignment: alignment)
            }
        }
    
        private func getAlignment() -> Alignment {
            switch message.speaker.type {
            case .player:
                return Alignment(horizontal: .trailing, vertical: .center)
            case .cs:
                return Alignment(horizontal: .leading, vertical: .center)
            case .system:
                fatalError("should not reach here.")
            }
        }
    }
  
    // MARK: - BubbleBackground
  
    struct BubbleBackground<Content: View>: View {
        let speakerType: CustomerServiceDTO.SpeakerType
        let content: () -> Content
    
        var body: some View {
            switch speakerType {
            case .player:
                ZStack(alignment: .bottomTrailing) {
                    content()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.from(.greyScaleWhite)))
          
                    Image("Combined Shape_right")
                        .alignmentGuide(.trailing) { $0[.trailing] + 3 }
                        .alignmentGuide(.bottom) { $0[.bottom] - 5 }
                }
            case .cs:
                ZStack(alignment: .bottomLeading) {
                    content()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.from(.textPrimary)))
          
                    Image("Combined Shape_left")
                        .alignmentGuide(.leading) { $0[.leading] - 3 }
                        .alignmentGuide(.bottom) { $0[.bottom] - 5 }
                }
            case .system:
                fatalError("should not reach here.")
            }
        }
    }
  
    // MARK: - TextContent
   
    struct TextContent: View {
        private let compositeContent: CompositeContent
    
        init(_ compositeContent: CompositeContent) {
            self.compositeContent = compositeContent
        }
    
        var body: some View {
            if hasContent() {
                compositeContent.contents.reduce(Text(""), { partialResult, content in
                    let text: Text
                    if content == compositeContent.contents.last {
                        let trimmedContent = content.text.trimmingCharacters(in: .newlines)
            
                        text = Text(trimmedContent)
                    }
                    else {
                        text = Text(content.text)
                    }
          
                    return partialResult + text
                        .addBold(content.textAttributes?.bold?.toBool() == true)
                        .addItalic(content.textAttributes?.italic?.toBool() == true)
                        .underline(content.textAttributes?.underline?.toBool() == true)
                })
                .id(ChattingListView.TestTag.text.rawValue)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    
        func hasContent() -> Bool {
            !compositeContent.contents
                .reduce("") { $0 + $1.text }
                .trimmingCharacters(in: .newlines)
                .isEmpty
        }
    }
  
    // MARK: - ImageContent
  
    struct ImageContent: View {
        @EnvironmentObject private var viewModel: ChattingListViewModel
    
        let compositeContent: CompositeContent
        let onTapImage: ((String) -> Void)?
    
        var body: some View {
            ForEach(compositeContent.contents, id: \.id) { content in
                ZStack(alignment: .center) {
                    if let downloadedImage = viewModel.downloadedImages[content.image?.thumbnailPath() ?? ""] {
                        if downloadedImage == viewModel.downloadFail {
                            reloadButton(content)
                        }
                        else {
                            Image(uiImage: downloadedImage)
                                .scaledToFit()
                                .onTapGesture {
                                    onTapImage?(content.image?.path() ?? "")
                                }
                        }
                    }
                    else {
                        SwiftUILoadingView(style: .small, iconColor: .primaryDefault, backgroundColor: .clear)
                            .fixedSize()
                    }
                }
                .id(ChattingListView.TestTag.image.rawValue)
            }
        }
    
        func reloadButton(_ content: CustomerServiceDTO.Content) -> some View {
            Button(
                action: {
                    guard let thumbnailPath = content.image?.thumbnailPath() else { return }
                    viewModel.downloadImage(thumbnailPath)
                },
                label: {
                    Image(systemName: "exclamationmark.arrow.triangle.2.circlepath")
                        .resizable()
                        .scaledToFit()
                })
                .frame(width: 24, height: 24)
                .foregroundColor(Color.from(.greyScaleIconDisable))
        }
    }
  
    // MARK: - LinkContent
  
    struct LinkContent: View {
        private let compositeContent: CompositeContent
    
        init(_ compositeContent: CompositeContent) {
            self.compositeContent = compositeContent
        }
    
        var body: some View {
            ForEach(reduceSameLink(compositeContent.contents), id: \.id) { content in
                if
                    let link = content.textAttributes?.link,
                    let url = URL(string: link)
                {
                    Link(destination: url) {
                        Text(link)
                            .underline(true, color: Color(UIColor.primaryDefault))
                            .localized(weight: .regular, size: 14, color: .primaryDefault)
                            .id(ChattingListView.TestTag.link.rawValue)
                    }
                }
            }
        }
    
        func reduceSameLink(_ contents: [CustomerServiceDTO.Content]) -> [CustomerServiceDTO.Content] {
            contents.reduce([CustomerServiceDTO.Content]()) { partialResult, content in
                var partialResult = partialResult
        
                if content.textAttributes?.link != partialResult.last?.textAttributes?.link {
                    partialResult.append(content)
                }
        
                return partialResult
            }
        }
    }

    // MARK: - SystemInfoCell
  
    struct SystemInfoCell: View {
        let message: CustomerServiceDTO.ChatMessage
        let showTopSeparator: Bool
        let showBottomSeparator: Bool
    
        var body: some View {
            VStack(alignment: .leading, spacing: 24) {
                if showTopSeparator {
                    Separator(color: .textPrimary, lineWidth: 0.5)
                }
        
                VStack(alignment: .leading, spacing: 12) {
                    if let createTime = message.createTime {
                        Text(createTime.toDateString())
                            .localized(weight: .regular, size: 12, color: .greyScaleWhite)
                    }
          
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(groupSameType(of: message.contents), id: \.id) { compositeContent in
                            ChattingListView.TextContent(compositeContent)
                                .localized(weight: .regular, size: 12, color: .greyScaleWhite)
                        }
                    }
                }
        
                if showBottomSeparator {
                    Separator(color: .textPrimary, lineWidth: 0.5)
                }
            }
            .padding(.top, showTopSeparator ? 12 : 0)
            .padding(.bottom, showBottomSeparator ? 18 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
  
    // MARK: - ChatContensBottomPosition
  
    struct ChatContensBottomPosition: View {
        static let id = "ChatContensBottomPosition"
    
        var body: some View {
            Color.clear
                .frame(height: 1)
                .id(Self.id)
        }
    }
}

// MARK: - Preview

struct ChattingListView_Previews: PreviewProvider {
    static var previews: some View {
        ChattingListView(
            messages: [
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
                    isProcessing: false),
            ])
    }
}
 