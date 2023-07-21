import SharedBu
import SwiftUI

struct PokerCardView: View {
  private let card: PokerCard
  
  init(_ card: PokerCard) {
    self.card = card
  }
  
  var body: some View {
    VStack(spacing: 0) {
      card.pokerNumber.mapToImage()
      
      card.pokerSuits.mapToImage()
    }
    .foregroundColor(card.pokerSuits.mapToTint())
    .padding(.top, 4)
    .padding(.bottom, 8)
    .frame(width: 36, height: 54)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .foregroundColor(.from(.greyScaleWhite))
        .padding(1)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .strokeBorder(Color.from(.greyScaleChatWindow), lineWidth: 2)))
  }
}

struct PokerCardView_Previews: PreviewProvider {
  static var previews: some View {
    PokerCardView(.init(pokerSuits: .clover, pokerNumber: .king))
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

extension PokerSuits {
  func mapToImage() -> Image {
    switch self {
    case .spades:
      return Image("PokerSuit-Spades")
    case .heart:
      return Image("PokerSuit-Heart")
    case .diamond:
      return Image("PokerSuit-Diamond")
    case .clover:
      return Image("PokerSuit-Clover")
    default:
      fatalError("should not reach here.")
    }
  }
  
  func mapToTint() -> Color {
    switch self {
    case .spades:
      return .from(.greyScaleBlack)
    case .heart:
      return .from(.primaryForLight)
    case .diamond:
      return .from(.primaryForLight)
    case .clover:
      return .from(.greyScaleBlack)
    default:
      fatalError("should not reach here.")
    }
  }
}

extension PokerNumber {
  func mapToImage() -> Image {
    switch self {
    case .ace:
      return Image("PokerNumber-Ace")
    case .two:
      return Image("PokerNumber-Two")
    case .three:
      return Image("PokerNumber-Three")
    case .four:
      return Image("PokerNumber-Four")
    case .five:
      return Image("PokerNumber-Five")
    case .six:
      return Image("PokerNumber-Six")
    case .seven:
      return Image("PokerNumber-Seven")
    case .eight:
      return Image("PokerNumber-Eight")
    case .nine:
      return Image("PokerNumber-Nine")
    case .ten:
      return Image("PokerNumber-Ten")
    case .jack:
      return Image("PokerNumber-Jack")
    case .queen:
      return Image("PokerNumber-Queen")
    case .king:
      return Image("PokerNumber-King")
    default:
      fatalError("should not reach here.")
    }
  }
}
