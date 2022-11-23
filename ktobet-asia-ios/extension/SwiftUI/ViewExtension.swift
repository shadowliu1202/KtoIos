
import SwiftUI
import CoreGraphics

extension View {
    @ViewBuilder
    func customizedStrokeBorder(color: Color, cornerRadius: CGFloat, lineWidth: CGFloat = 1) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(lineWidth: lineWidth)
                    .foregroundColor(color)
            )
    }
    
    func backgroundColor(_ color: Color) -> some View {
        background(color)
    }
    
    func pageBackgroundColor(_ color: Color) -> some View {
        background(
            color.ignoresSafeArea()
        )
    }
    
    @ViewBuilder
    func customizedFont(fontWeight: KTOFontWeight, size: CGFloat, color: KTOTextColor? = nil) -> some View {
        LocalizeFont(fontWeight: fontWeight, size: size, color: color) {
            self
        }
    }
    
    @ViewBuilder
    func visibility(_ visibility: Visibility) -> some View {
        switch visibility {
        case .visible:
            self
        case .invisible:
            self.hidden()
        case .gone:
            EmptyView()
        }
    }

    @ViewBuilder
    func wrappedInScrollView(when condition: Bool, _ axis: Axis.Set = .vertical, showsIndicators: Bool = true) -> some View {
        if condition {
            ScrollView(axis, showsIndicators: showsIndicators) {
                self
            }
        } else {
            self
        }
    }
    
    func generateHighlightSentence(fullSentence: String, generalColor: KTOTextColor, highlightWords: [String], highlightColor: KTOTextColor) -> Text {
        var words = highlightWords
        
        for word in words {
            if fullSentence.range(of: word) == nil {
                guard let index = words.firstIndex(of: word) else { continue }
                words.remove(at: index)
            }
        }
        
        var sentence = fullSentence
        var highlightSentence: Text = Text("")
        
        words.sort { lhs, rhs in
            let lhsStartIndex = sentence.range(of: lhs)!.lowerBound
            let rhsStartIndex = sentence.range(of: rhs)!.lowerBound
            
            if lhsStartIndex == rhsStartIndex {
                return lhs.count > rhs.count
            }
            
            return lhsStartIndex < rhsStartIndex
        }
        
        for word in words {
            guard let range = sentence.range(of: word) else { continue }
            
            highlightSentence = highlightSentence + Text(sentence[..<range.lowerBound]).foregroundColor(generalColor.value)
            highlightSentence = highlightSentence + Text(word).foregroundColor(highlightColor.value)
            
            sentence = String(sentence[range.upperBound...])
        }
        
        highlightSentence = highlightSentence + Text(sentence).foregroundColor(generalColor.value)
        
        return highlightSentence
    }
}

enum Visibility {
    case visible
    case invisible
    case gone
}
