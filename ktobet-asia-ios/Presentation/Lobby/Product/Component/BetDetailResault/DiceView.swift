import sharedbu
import SwiftUI

struct DiceView: View {
    let dices: [DiceNumber]?
  
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

extension DiceNumber {
    func mapToImage() -> Image {
        switch self {
        case .one:
            return Image("DiceNumber-One")
        case .two:
            return Image("DiceNumber-Two")
        case .three:
            return Image("DiceNumber-Three")
        case .four:
            return Image("DiceNumber-Four")
        case .five:
            return Image("DiceNumber-Five")
        case .six:
            return Image("DiceNumber-Six")
        }
    }
}

struct DiceView_Previews: PreviewProvider {
    static var previews: some View {
        DiceView(dices: [.one, .two, .three, .four, .five, .six])
            .backgroundColor(.greyScaleBlack, ignoresSafeArea: .all)
    }
}
