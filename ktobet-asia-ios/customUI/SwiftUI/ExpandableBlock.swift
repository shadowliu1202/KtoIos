import SwiftUI

struct ExpandableBlock<Content: View>: View {
    var inspection = Inspection<Self>()
    enum Identifier: String {
        case blockHeader
        case blockContent
    }
    
    @State private var isExpand = false
    
    let title: String
    let isLastBlock: Bool
    let contentAlignment: HorizontalAlignment
    var content: Content
    
    init(title: String, isLastBlock: Bool = false, contentAlignment: HorizontalAlignment = .center, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isLastBlock = isLastBlock
        self.contentAlignment = contentAlignment
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: contentAlignment, spacing: 0) {
            VStack(spacing: 0) {
                CustomizedDivider(color: .dividerGray)
                
                LimitSpacer(11)
                
                HStack {
                    Text(title)
                        .customizedFont(fontWeight: .semibold, size: 16, color: .black)
                    Spacer()
                    Image(isExpand ? "termsArrowUp" : "termsArrowDown")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                
                LimitSpacer(11)
                
                if isExpand || isLastBlock {
                    CustomizedDivider(color: .dividerGray)
                }
            }
            .contentShape(Rectangle())
            .id(Identifier.blockHeader.rawValue)
            .onTapGesture {
                withAnimation {
                    isExpand.toggle()
                }
            }
            
            if isExpand {
                content.id(Identifier.blockContent.rawValue)
            }
        }
        .onReceive(inspection.notice) {
            self.inspection.visit(self, $0)
        }
    }
}

struct ExpandableBlock_Previews: PreviewProvider {
    static var previews: some View {
        ExpandableBlock(title: "Title", isLastBlock: true) {
            VStack {
                Text("Hello World!")
            }
            .padding()
        }
        .padding(.horizontal, 30)
    }
}
