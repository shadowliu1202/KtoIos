import sharedbu
import SwiftUI

struct BetDetailResultView: View {
  let result: ProductDTO.Result
  
  var body: some View {
    switch result.displayType {
    case .verticalpokerset: PokerSetVerticalView(cards: result.cards)
    case .horizontalpokerset: PokerSetHorizontalView(cards: result.cards)
    case .dice: DiceView(dices: result.dices)
    case .roulette: RouletteView(number: result.roulette)
    case .fishshrimpcrab: FishShrimpCrabView(dices: result.chineseDice)
    case .fantan: FanTanView(count: result.fanTan)
    case .colorplate: ColorPlateView(plates: result.colorPlates)
    case .none: EmptyView()
        
    default: fatalError("should not reach here.")
    }
  }
}
