import sharedbu
import SwiftUI

struct SharedOTPVerificationFailureView: View {
  private let message: String?
  private let buttonOnClick: (() -> Void)?

  init(
    message: String? = nil,
    buttonOnClick: (() -> Void)? = nil)
  {
    self.message = message
    self.buttonOnClick = buttonOnClick
  }

  var body: some View {
    PageContainer {
      VStack(spacing: 40) {
        Image("Failed")
          .resizable()
          .scaledToFill()
          .frame(width: 96, height: 96)

        VStack(spacing: 12) {
          Text(key: "cps_secruity_verification_failure")
            .localized(weight: .semibold, size: 24, color: .textPrimary)

          if let message {
            Text(message)
              .localized(weight: .medium, size: 14, color: .textPrimary)
          }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)

        PrimaryButton(
          title: Localize.string("common_back"),
          action: {
            buttonOnClick?()
          })
      }
      .padding(.horizontal, 30)
      .frame(maxHeight: .infinity, alignment: .top)
    }
    .pageBackgroundColor(.greyScaleDefault)
  }
}

struct SharedOTPVerificationFailureView_Previews: PreviewProvider {
  static var previews: some View {
    SharedOTPVerificationFailureView()
  }
}
