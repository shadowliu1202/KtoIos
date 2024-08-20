import Foundation
import NavigationBackport
import SwiftUI

struct ErrorPage: View {
    @EnvironmentObject var navigator: PathNavigator
    private(set) var title: LocalizedStringKey? = nil
    private(set) var message: LocalizedStringKey? = nil
    private(set) var button: LocalizedStringKey = "common_back"
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
                            .font(weight: .semibold, size: 24)

                        if let message {
                            Text(message)
                                .font(weight: .medium, size: 14)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                    PrimaryButton(
                        key: button,
                        action: {
                            if let backAction {
                                backAction()
                            } else {
                                navigator.popToRoot()
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
