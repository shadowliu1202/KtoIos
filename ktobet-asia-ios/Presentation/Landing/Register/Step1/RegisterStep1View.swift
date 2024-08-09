import sharedbu
import SwiftUI

struct RegisterStep1View: View {
    @AppStorage(UserDefaults.Key.cultureCode.rawValue) var cultureCode: String?
    @State private var moveToNext: Bool = false

    var body: some View {
        RegisterStep1Content(
            activeLocales: Configuration.supportLocale,
            currentLocale: SupportLocale.companion.create(language: cultureCode!),
            moveToNext: $moveToNext,
            onLocaleSelect: { locale in
                handlePlayerSessionChange(locale: locale)
            }
        )
        NavigationLink(
            isActive: $moveToNext,
            destination: { RegisterStep2View() },
            label: {}
        )
    }
}

struct RegisterStep1Content: View {
    let activeLocales: [SupportLocale]
    let currentLocale: SupportLocale
    @Binding var moveToNext: Bool
    let onLocaleSelect: (SupportLocale) -> Void

    @Environment(\.showDialog) private var showDialog

    var body: some View {
        LandingViewScaffold(items: [.cs()]) {
            PageContainer(scrollable: true) {
                VStack(spacing: 0) {
                    Text("register_step1_title_1")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(weight: .medium, size: 14)
                    HStack {
                        Text("register_step1_title_2")
                            .font(weight: .semibold, size: 24)

                        Image("Tips")
                            .onTapGesture {
                                showDialog(info: ShowDialog.Info(
                                    title: Localize.string("common_tip_title_warm"),
                                    message: Localize.string("common_tip_content_bind")
                                ))
                            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    LimitSpacer(30)

                    ForEach(activeLocales) { locale in
                        LocaleItem(
                            key: optionDisplayText(by: locale),
                            isSelected: currentLocale == locale,
                            action: { onLocaleSelect(locale) }
                        )

                        if activeLocales.last != locale {
                            LimitSpacer(12)
                        }
                    }

                    LimitSpacer(40)

                    PrimaryButton(key: "common_next") {
                        moveToNext = true
                    }

                    LimitSpacer(24)

                    Text("register_step1_tips_1")
                        .multilineTextAlignment(.center)
                        .font(weight: .medium, size: 12)
                        .foregroundStyle(.textSecondary)

                    LimitSpacer(8)

                    NavigationLink {
                        LandingServiceTermView()
                    } label: {
                        Text("register_step1_tips_1_highlight")
                            .multilineTextAlignment(.center)
                            .font(weight: .medium, size: 12)
                            .foregroundStyle(.primaryDefault)
                    }
                }
                .padding(.horizontal, 30)
            }
        }
    }

    @ViewBuilder
    private func LocaleItem(key: LocalizedStringKey, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { action() }, label: {
            HStack {
                Text(key)
                    .font(weight: .medium, size: 14)
                    .foregroundStyle(isSelected ? .greyScaleWhite : .textPrimary)
                Spacer()
                if isSelected {
                    Image("Single Selection (Selected)")
                } else {
                    Image("Single Selection (Empty)")
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 18)
        })
        .backgroundColor(isSelected ? .inputFocus : .inputDefault)
        .cornerRadius(8)
    }

    private func optionDisplayText(by locale: SupportLocale) -> LocalizedStringKey {
        switch onEnum(of: locale) {
        case .china:
            "register_language_option_chinese"
        case .vietnam:
            "register_language_option_vietnam"
        }
    }
}

extension SupportLocale: Identifiable {}

struct RegisterStep1View_Previews: PreviewProvider {
    static var previews: some View {
        RegisterStep1Content(
            activeLocales: [.China(), .Vietnam()],
            currentLocale: .Vietnam(),
            moveToNext: .constant(false),
            onLocaleSelect: { _ in }
        )
        .environment(\.locale, .init(identifier: "vi-vn"))
    }
}
