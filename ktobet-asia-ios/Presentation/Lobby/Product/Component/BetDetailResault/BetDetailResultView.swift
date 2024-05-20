import sharedbu
import SwiftUI

struct BetDetailResultView: View {
    let result: ProductDTO.Result
  
    var body: some View {
        switch result.displayType {
        case .verticalPokerSet: PokerSetVerticalView(cards: result.cards)
        case .horizontalPokerSet: PokerSetHorizontalView(cards: result.cards)
        case .dice: DiceView(dices: result.dices)
        case .roulette: RouletteView(number: result.roulette)
        case .fishShrimpCrab: FishShrimpCrabView(dices: result.chineseDice)
        case .fanTan: FanTanView(count: result.fanTan)
        case .colorPlate: ColorPlateView(plates: result.colorPlates)
        case .none: EmptyView()
        }
    }
}
