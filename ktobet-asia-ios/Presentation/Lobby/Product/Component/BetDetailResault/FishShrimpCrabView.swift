import sharedbu
import SwiftUI

struct FishShrimpCrabView: View {
    let dices: [ChineseDice]?
  
    var body: some View {
        HStack(spacing: 16) {
            if let dices {
                ForEach(dices.indices, id: \.self) {
                    dices[$0].mapToImage()
                        .resizable()
                        .frame(width: 44, height: 44)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .onViewDidLoad {
            assert(dices != nil)
        }
    }
}

extension ChineseDice {
    func mapToImage() -> Image {
        switch self {
        case .gourd:
            return Image("ChineseDice-Gourd")
        case .crab:
            return Image("ChineseDice-Crab")
        case .fish:
            return Image("ChineseDice-Fish")
        case .chicken:
            return Image("ChineseDice-Chicken")
        case .shrimp:
            return Image("ChineseDice-Shrimp")
        case .coin:
            return Image("ChineseDice-Coin")
        }
    }
}

struct FishShrimpCrabView_Previews: PreviewProvider {
    static var previews: some View {
        FishShrimpCrabView(dices: [.gourd, .crab, .fish, .chicken, .shrimp, .coin])
    }
}
