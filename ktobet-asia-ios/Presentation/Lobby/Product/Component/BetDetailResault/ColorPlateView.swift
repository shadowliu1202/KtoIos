import SharedBu
import SwiftUI

struct ColorPlateView: View {
  let plates: [Plate]?
  
  var body: some View {
    VStack(spacing: 8) {
      if let plates {
        let rows = plates.chunked(into: 2)
        
        ForEach(rows.indices, id: \.self) { index in
          let row = rows[index]
          
          HStack(spacing: 16) {
            ForEach(row.indices, id: \.self) {
              row[$0].mapToImage()
                .resizable()
                .frame(width: 44, height: 44)
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity)
    .onViewDidLoad {
      assert(plates != nil)
    }
  }
}

extension Plate {
  func mapToImage() -> Image {
    switch self {
    case .red:
      return Image("Plate-Red")
    case .white:
      return Image("Plate-White")
    default:
      fatalError("should not reach here.")
    }
  }
}

struct ColorPlateView_Previews: PreviewProvider {
  static var previews: some View {
    ColorPlateView(plates: [.red, .red, .white, .red])
  }
}
