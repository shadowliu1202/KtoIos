import sharedbu
import SwiftUI

struct PokerCardView: View {
  private let card: Poker
  
  init(_ card: Poker) {
    self.card = card
  }
  
  var body: some View {
    PockerBackgroundView()
      .overlay(
        VStack {
          switch card {
          case let card as PokerStandard:
            StandarContentView(card)
          case let card as PokerJoker:
            JokerContentView(card)
          default:
            fatalError("should not reach here.")
          }
        })
  }
}

private struct PockerBackgroundView: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 8)
      .foregroundColor(.from(.greyScaleWhite))
      .padding(1)
      .frame(width: 36, height: 54)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .strokeBorder(Color.from(.greyScaleChatWindow), lineWidth: 2))
  }
}
    
private struct StandarContentView: View {
  private let card: PokerStandard
  
  init(_ card: PokerStandard) {
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
  }
}

private struct JokerContentView: View {
  private let card: PokerJoker
  
  init(_ card: PokerJoker) {
    self.card = card
  }
     
  var body: some View {
    VStack(spacing: 2) {
      Image("PokerNumber-Star")
         
      Image("PokerSuit-Joker")
    }
    .foregroundColor(card.mapToTint())
  }
}
 
struct PokerCardView_Previews: PreviewProvider {
  static var previews: some View {
    HStack(spacing: 10) {
      PokerCardView(PokerStandard(pokerSuits: .clover, pokerNumber: .king))
      
      PokerCardView(PokerJoker.big)
    }
    .previewLayout(.fixed(width: 100, height: 100))
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

extension PokerJoker {
  func mapToTint() -> Color {
    switch self {
    case PokerJoker.little:
      return .from(.greyScaleBlack)
    case PokerJoker.big:
      return .from(.primaryForLight)
    default:
      fatalError("should not reach here.")
    }
  }
}
