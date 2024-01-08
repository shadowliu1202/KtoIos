import sharedbu
import SwiftUI

struct FanTanView: View {
  let count: KotlinInt?
  
  var body: some View {
    VStack {
      if let count {
        HStack(spacing: 16) {
          ForEach(0..<count.intValue, id: \.self) { _ in
            Image("FanTan")
              .resizable()
              .frame(width: 44, height: 44)
          }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .center)
      }
    }
    .onViewDidLoad {
      assert(count != nil)
    }
  }
}

struct FanTanView_Previews: PreviewProvider {
  static var previews: some View {
    FanTanView(count: KotlinInt(int: 3))
      .backgroundColor(.greyScaleBlack, ignoresSafeArea: .all)
  }
}
