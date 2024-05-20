import sharedbu
import SwiftUI

struct RouletteView: View {
    let number: KotlinInt?
  
    var body: some View {
        VStack {
            if let number {
                Circle()
                    .fill(Color.from(.primaryForLight))
                    .frame(height: 40)
                    .overlay(
                        Text(number.intValue.description)
                            .localized(weight: .semibold, size: 20, color: .greyScaleWhite))
                    .padding(.vertical, 10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .onViewDidLoad {
            assert(number != nil)
        }
    }
}

struct RouletteView_Previews: PreviewProvider {
    static var previews: some View {
        RouletteView(number: KotlinInt(int: 10))
    }
}
