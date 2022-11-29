
import SwiftUI
import CoreGraphics

extension View {
    
    func strokeBorder(color: UIColor, cornerRadius: CGFloat, lineWidth: CGFloat = 1) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(lineWidth: lineWidth)
                .foregroundColor(.from(color))
        )
    }
    
    func backgroundColor(_ color: UIColor, alpha: CGFloat = 1) -> some View {
        background(
            Color.from(color, alpha: alpha)
        )
    }
    
    func pageBackgroundColor(_ color: UIColor, alpha: CGFloat = 1) -> some View {
        background(
            Color.from(color, alpha: alpha).ignoresSafeArea()
        )
    }
    
    func localized(weight: KTOFontWeight, size: CGFloat, color: UIColor = .clear) -> some View {
        LocalizeFont(
            fontWeight: weight,
            size: size,
            color: color
        ) { self }
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
    
    func generateHighlightSentence(
        fullSentence: String,
        generalColor: UIColor,
        highlightWords: [String],
        highlightColor: UIColor
    ) -> Text {
        
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
            
            highlightSentence = highlightSentence + Text(sentence[..<range.lowerBound]).foregroundColor(.from(generalColor))
            highlightSentence = highlightSentence + Text(word).foregroundColor(.from(highlightColor))
            
            sentence = String(sentence[range.upperBound...])
        }
        
        highlightSentence = highlightSentence + Text(sentence).foregroundColor(.from(generalColor))
        
        return highlightSentence
    }
}

enum Visibility {
    case visible
    case invisible
    case gone
}
