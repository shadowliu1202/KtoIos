import sharedbu
import SwiftUI

struct PokerSetHorizontalView: View {
  private let columns = [GridItem(.flexible()), GridItem(.flexible())]

  let cards: [PokerGroup]?
  
  var body: some View {
    LazyVGrid(columns: columns) {
      if let cards {
        ForEach(cards.indices, id: \.self) {
          PokerGroupView(cards[$0])
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .center)
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
    VStack(spacing: 8) {
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
    VStack(spacing: 8) {
      if !pokerSection.title.isEmpty {
        Text(pokerSection.title)
          .localized(weight: .regular, size: 14, color: .greyScaleWhite.withAlphaComponent(0.6))
      }
      
      if !pokerSection.cards.isEmpty {
        HStack(spacing: 8) {
          ForEach(pokerSection.cards.indices, id: \.self) {
            PokerCardView(pokerSection.cards[$0])
          }
        }
      }
    }
  }
}

struct PokerSetHorizontalView_Previews: PreviewProvider {
  static let stubPokerGroup: [PokerGroup] = [
    .init(title: "龙", cards: [
      .init(title: "", cards: [
        Poker.Standard(pokerSuits: .heart, pokerNumber: .king),
        Poker.Standard(pokerSuits: .clover, pokerNumber: .three),
        Poker.Standard(pokerSuits: .clover, pokerNumber: .seven)
      ])
    ]),
    .init(title: "凤", cards: [
      .init(title: "", cards: [
        Poker.Standard(pokerSuits: .spades, pokerNumber: .king),
        Poker.Standard(pokerSuits: .diamond, pokerNumber: .six),
        Poker.Standard(pokerSuits: .heart, pokerNumber: .ten)
      ])
    ])
  ]
  
  static var previews: some View {
    PokerSetHorizontalView(cards: stubPokerGroup)
      .backgroundColor(.greyScaleBlack, ignoresSafeArea: .all)
  }
}
