import SwiftUI

struct CryptoVideoTutorialView: View {
  @Environment(\.presentationMode) var presentation

  var body: some View {
    ZStack {
      Button(
        action: {
          presentation.wrappedValue.dismiss()
        },
        label: {
          Image("close.circle")
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .foregroundColor(.white)
        })
        .frame(
          maxWidth: .infinity,
          maxHeight: .infinity,
          alignment: .topTrailing)
        .padding(.trailing, 30)
        .padding(.top, 20)

      YTPlayer(videoId: "7t6X_b60Oug")
        .aspectRatio(
          CGSize(width: 1, height: 1.1),
          contentMode: .fit)
    }
    .pageBackgroundColor(.blackPure, alpha: 0.8)
  }
}

struct CryptoVideoTutorialView_Previews: PreviewProvider {
  static var previews: some View {
    CryptoVideoTutorialView()
  }
}
