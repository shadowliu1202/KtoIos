import Foundation
import SwiftUI

struct ResetPasswordStep3View: View {
    @Environment(\.handleError) var handleError
    @Environment(\.toastMessage) var toastMessage
    @Environment(\.popToRoot) var popToRoot
    @StateObject var resetPassword = ResetPassword()
    @State var moveToErrorPage: Bool = false
    var body: some View {
        ContentView(
            password: $resetPassword.state.password,
            confirmPassword: $resetPassword.state.confirmPassword,
            state: resetPassword.state
        ) { password in
            resetPassword.reset(password: password)
        }
        .onConsume(handleError, resetPassword) { event in
            switch event {
            case .resetSuccess:
                toastMessage(Localize.string("login_resetpassword_success"), .success)
                popToRoot()
            case .navToError:
                moveToErrorPage = true
            }
        }
        NavigationLink(
            destination: ErrorPage(title: "login_resetpassword_fail_title"),
            isActive: $moveToErrorPage,
            label: {}
        )
    }
}

private struct ContentView: View {
    @Environment(\.showDialog) var showDialog
    @Environment(\.popToRoot) var popToRoot
    @Binding var password: String?
    @Binding var confirmPassword: String?
    var state: ResetPassword.State
    let onResetPassword: (String) -> Void
    var body: some View {
        LandingViewScaffold(navItem: .close {
            showDialog(
                info: ShowDialog.Info(
                    title: Localize.string("common_confirm_cancel_operation"),
                    message: Localize.string("login_resetpassword_cancel_content"),
                    confirm: { popToRoot() },
                    cancel: {}
                )
            )
        },
        items: [.cs()]) {
            PageContainer(scrollable: true) {
                Text("login_resetpassword_step3_title")
                    .localized(weight: .medium, size: 14, color: .textPrimary)
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/ .infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
                Text("login_resetpassword_step3_title_2")
                    .localized(weight: .semibold, size: 24, color: .textPrimary)
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/ .infinity/*@END_MENU_TOKEN@*/, alignment: .leading)

                Spacer(minLength: 30)

                PasswordConfirmView(
                    password: $password ?? "",
                    passwordConfirm: $confirmPassword ?? "",
                    errorMessage: state.verification?.errorMessage() ?? ""
                )
                Spacer(minLength: 12)

                Text("common_password_tips_1")
                    .localized(weight: .medium, size: 14, color: .textPrimary)
                    .frame(maxWidth: /*@START_MENU_TOKEN@*/ .infinity/*@END_MENU_TOKEN@*/, alignment: .leading)

                Spacer(minLength: 40)

                PrimaryButton(
                    title: Localize.string("common_next"),
                    action: {
                        if let password {
                            onResetPassword(password)
                        }
                    }
                )
                .disabled(state.verification != .valid)
            }
            .padding(.horizontal, 30)
        }
    }
}

extension ResetPassword.State.PasswordVerification {
    func errorMessage() -> String? {
        switch self {
        case .errorFormat:
            Localize.string("common_field_format_incorrect")
        case .notMatch:
            Localize.string("register_step2_password_not_match")
        case .isEmpty:
            Localize.string("common_password_not_filled")
        case .valid:
            nil
        }
    }
}

struct Step3ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(password: .constant(""), confirmPassword: .constant(""), state: .init()) { _ in
        }
    }
}
