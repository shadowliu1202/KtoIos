import SwiftUI

struct EmptyNotificationView: View {
  var body: some View {
    VStack(spacing: 0) {
      Image("NotificationEmpty")

      Text(Localize.string("common_no_notification"))
        .font(.custom("PingFangSC-Regular", size: 14))
        .foregroundColor(Color("textPrimaryDustyGray"))
        .padding(.top, 32)
    }
    .offset(y: -30)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color("blackTwo"))
    .ignoresSafeArea(.keyboard)
  }
}

struct EmptyNotificationView_Previews: PreviewProvider {
  static var previews: some View {
    EmptyNotificationView()
  }
}
