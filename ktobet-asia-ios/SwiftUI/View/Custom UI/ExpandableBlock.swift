import SwiftUI

struct ExpandableBlock<Content: View>: View {
    enum Identifier: String {
        case blockHeader
        case blockContent
    }
    
    var inspection = Inspection<Self>()

    @State private var isExpand = false
    
    let title: String
    let bottomLineVisible: Bool
    let contentAlignment: HorizontalAlignment
    var content: Content
    
    init(title: String, bottomLineVisible: Bool = false, contentAlignment: HorizontalAlignment = .center, @ViewBuilder content: () -> Content) {
        self.title = title
        self.bottomLineVisible = bottomLineVisible
        self.contentAlignment = contentAlignment
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: contentAlignment, spacing: 0) {
            VStack(spacing: 0) {
                Separator(color: .gray3C3E40)
                
                LimitSpacer(11)
                
                HStack {
                    Text(title)
                        .localized(weight: .semibold, size: 16, color: .black)
                    Spacer()
                    Image(isExpand ? "termsArrowUp" : "termsArrowDown")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
                
                LimitSpacer(11)
                
                if isExpand || bottomLineVisible {
                    Separator(color: .gray3C3E40)
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
        .onInspected(inspection, self)
    }
}

struct ExpandableBlock_Previews: PreviewProvider {
    static var previews: some View {
        ExpandableBlock(title: "Title", bottomLineVisible: true) {
            VStack {
                Text("Hello World!")
            }
            .padding()
        }
        .padding(.horizontal, 30)
    }
}
