import sharedbu
import SwiftUI

struct PokerSetVerticalView: View {
  let cards: [PokerGroup]?
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      if let cards {
        ForEach(cards.indices, id: \.self) {
          PokerGroupView(cards[$0])
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .onViewDidLoad {
      assert(cards != nil)
    }
  }
}

private struct PokerGroupView: View {
  private let pokerGroup: PokerGroup
  
  init(_ pokerGroup: PokerGroup) {
    self.pokerGroup = pokerGroup
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(pokerGroup.title)
        .localized(weight: .regular, size: 14, color: .greyScaleWhite)
      
      ForEach(pokerGroup.cards.indices, id: \.self) { PokerSectionView(pokerGroup.cards[$0])
      }
    }
  }
}

private struct PokerSectionView: View {
  private let pokerSection: PokerSection
  
  init(_ pokerSection: PokerSection) {
    self.pokerSection = pokerSection
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if !pokerSection.title.isEmpty {
        Text(pokerSection.title)
          .localized(weight: .regular, size: 14, color: .greyScaleWhite.withAlphaComponent(0.6))
      }
      
      if !pokerSection.cards.isEmpty {
        FlowLayout(
          items: pokerSection.cards,
          hSpacing: 8,
          vSpacing: 8,
          content: { PokerCardView($0) })
      }
    }
  }
}

struct PokerSetVerticalView_Previews: PreviewProvider {
  static let stubPokerGroup: [PokerGroup] = [
    .init(title: "banker", cards: [
      .init(title: "", cards: [
        Poker.Standard(pokerSuits: .heart, pokerNumber: .king),
        Poker.Standard(pokerSuits: .clover, pokerNumber: .three),
        Poker.Standard(pokerSuits: .clover, pokerNumber: .seven)
      ])
    ]),
    .init(title: "Player 1", cards: [
      .init(title: "", cards: [
        Poker.Standard(pokerSuits: .spades, pokerNumber: .king),
        Poker.Standard(pokerSuits: .diamond, pokerNumber: .six),
        Poker.Standard(pokerSuits: .heart, pokerNumber: .ten)
      ])
    ]),
    .init(title: "Player 2", cards: [
      .init(title: "No Player", cards: [])
    ]),
    .init(title: "Player 3", cards: [
      .init(title: "Split", cards: [
        Poker.Standard(pokerSuits: .heart, pokerNumber: .three),
        Poker.Standard(pokerSuits: .heart, pokerNumber: .five),
        Poker.Standard(pokerSuits: .spades, pokerNumber: .king)
      ]),
      .init(title: "Split", cards: [
        Poker.Standard(pokerSuits: .spades, pokerNumber: .three),
        Poker.Standard(pokerSuits: .spades, pokerNumber: .jack),
      ])
    ]),
  ]
  
  static var previews: some View {
    PokerSetVerticalView(cards: stubPokerGroup)
      .backgroundColor(.greyScaleBlack, ignoresSafeArea: .all)
  }
}
