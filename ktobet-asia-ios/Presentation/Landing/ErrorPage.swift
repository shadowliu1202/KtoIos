import Foundation
import SwiftUI

struct ErrorPage: View {
    @Environment(\.popToRoot) var popToRoot
    private(set) var title: LocalizedStringKey? = nil
    private(set) var message: LocalizedStringKey? = nil
    private(set) var button: String = Localize.string("common_back")
    private(set) var backAction: (() -> Void)? = nil

    var body: some View {
        LandingViewScaffold(navItem: .empty(), items: [.cs()]) {
            PageContainer(scrollable: true) {
                VStack(spacing: 40) {
                    Image("Failed")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 96, height: 96)

                    VStack(spacing: 12) {
                        Text(title ?? "")
                            .localized(weight: .semibold, size: 24, color: .textPrimary)

                        if let message {
                            Text(message)
                                .localized(weight: .medium, size: 14, color: .textPrimary)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                    PrimaryButton(
                        title: button,
                        action: {
                            if let backAction {
                                backAction()
                            } else {
                                popToRoot()
                            }
                        }
                    )
                }
                .padding(.horizontal, 30)
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }
}

struct ErrorPage_Previews: PreviewProvider {
    static var previews: some View {
        ErrorPage(title: "login_resetpassword_fail_title")
            .environment(\.locale, .init(identifier: "zh-cn"))
    }
}
