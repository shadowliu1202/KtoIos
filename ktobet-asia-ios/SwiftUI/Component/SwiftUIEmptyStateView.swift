import SwiftUI

extension SwiftUIEmptyStateView {
  enum Identifier: String {
    case description
  }
  
  enum KeyboardAppearance {
    case possible
    case impossible
  }
}

struct SwiftUIEmptyStateView: View {
  private let iconImage: Image
  private let description: String
  private let keyboardAppearance: KeyboardAppearance

  init(
    iconImage: Image,
    description: String,
    keyboardAppearance: KeyboardAppearance)
  {
    self.iconImage = iconImage
    self.description = description
    self.keyboardAppearance = keyboardAppearance
  }

  var body: some View {
    GeometryReader { geometryProxy in
      ScrollView {
        ZStack {
          VStack(spacing: 0) {
            iconImage
              .resizable()
              .scaledToFit()
              .frame(width: 128, height: 128)

            Text(description)
              .localized(weight: .regular, size: 14, color: .textPrimary)
              .multilineTextAlignment(.center)
              .id(Identifier.description.rawValue)
          }
          .offset(
            y: keyboardAppearance == .impossible
              ? -74
              : 80)
        }
        .frame(
          width: geometryProxy.size.width,
          height: geometryProxy.size.height,
          alignment: keyboardAppearance == .impossible
            ? .center
            : .top)
      }
    }
  }
}

struct SwiftUIEmptyStateView_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
      Color.black
      
      VStack(spacing: 0) {
        LimitSpacer(30)
        
        Rectangle()
          .frame(height: 100)
          .padding(.horizontal, 20)
          .foregroundColor(.gray)
        
        SwiftUIEmptyStateView(
          iconImage: Image("No Records"),
          description: "没有投注历史",
          keyboardAppearance: .possible)
      }
    }
    .previewDisplayName("Has Keyboard")
    
    ZStack {
      Color.black
      
      SwiftUIEmptyStateView(
        iconImage: Image("No Records"),
        description: "没有投注历史",
        keyboardAppearance: .impossible)
    }
    .previewDisplayName("No Keyboard")
  }
}
