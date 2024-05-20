import RxSwift
import sharedbu
import SwiftUI

struct CryptoSelectView<ViewModel>: View
    where ViewModel: CryptoDepositViewModelProtocol & ObservableObject
{
    @StateObject var viewModel: ViewModel

    private let disposeBag = DisposeBag()

    let playerConfig: PlayerConfiguration

    var userGuideOnTap = { }
    var tutorialOnTap = { }
    var submitButtonOnSuccess = { (_: CommonDTO.WebUrl) in }
    var inspection = Inspection<Self>()

    var body: some View {
        ScrollView(showsIndicators: false) {
            PageContainer {
                VStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 16) {
                        Header(
                            locale: playerConfig.supportLocale,
                            userGuideOnTap: userGuideOnTap,
                            tutorialOnTap: tutorialOnTap)
                        Separator()
                        SelectorList()
                        Separator()
                    }
          
                    PrimaryButton(
                        title: Localize.string("deposit_offline_step1_button"),
                        action: {
                            viewModel.confirm()
                                .subscribe(onSuccess: {
                                    submitButtonOnSuccess($0)
                                })
                                .disposed(by: disposeBag)
                        })
                        .disabled(viewModel.submitButtonDisable)
                        .padding(.horizontal, 30)
                        .id(CryptoSelectView.Identifier.submitBtn.rawValue)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onPageLoading(viewModel.options.isEmpty)
        .pageBackgroundColor(.greyScaleDefault)
        .environmentObject(viewModel)
        .environment(\.playerLocale, playerConfig.supportLocale)
        .onAppear {
            viewModel.fetchOptions()
        }
        .onInspected(inspection, self)
    }
}

extension CryptoSelectView {
    enum Identifier: String {
        case tutorial
        case userGuide
        case selectorRows
        case submitBtn
    }

    struct Header: View {
        let locale: SupportLocale

        var userGuideOnTap: () -> Void
        var tutorialOnTap: () -> Void
        var inspection = Inspection<Self>()

        var body: some View {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(Localize.string("common_crypto"))
                        .localized(
                            weight: .semibold,
                            size: 24,
                            color: .greyScaleWhite)

                    HStack(spacing: 8) {
                        UIKitLabel {
                            $0.attributedText =
                                hintAttributed(from: Localize.string("cps_crypto_currency_guide_hint"))
                        }

                        Image("iconChevronRightRed7")
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        userGuideOnTap()
                    }
                    .id(CryptoSelectView.Identifier.userGuide.rawValue)

                    Text(Localize.string("deposit_crypto_video_tutorial"))
                        .localized(
                            weight: .medium,
                            size: 14,
                            color: .primaryDefault)
                        .onTapGesture {
                            tutorialOnTap()
                        }
                        .id(CryptoSelectView.Identifier.tutorial.rawValue)
                        .visibleLocale(availableLocales: .Vietnam(), currentLocale: locale)
                }

                Text(Localize.string("cps_select_crypto_type"))
                    .localized(
                        weight: .medium,
                        size: 16,
                        color: .textPrimary)
            }
            .padding(.leading, 30)
            .onInspected(inspection, self)
        }

        func hintAttributed(from hint: String) -> NSAttributedString {
            let split = hint.split(separator: "?")

            let result = hint
                .attributed
                .textColor(.textPrimary)
                .font(weight: .medium, locale: locale, size: 14)

            if let last = split.last {
                result
                    .highlights(
                        weight: .medium,
                        locale: locale,
                        size: 14,
                        color: .primaryDefault,
                        subStrings: [String(last)],
                        skip: "\(split.first ?? "")")
            }

            return result
        }
    }

    struct SelectorList: View {
        @EnvironmentObject var viewModel: ViewModel

        var inspection = Inspection<Self>()

        var body: some View {
            VStack(spacing: 0) {
                VStack(spacing: 17) {
                    ForEach(viewModel.options.indices, id: \.self) { index in
                        let item = viewModel.options[index]
                        HStack(spacing: 0) {
                            Image(item.icon)

                            LimitSpacer(16)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.option.name)
                                    .localized(weight: .medium, size: 14, color: .greyScaleWhite)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(minHeight: item.option.promotion.isNotEmpty ? nil : 40)
                                Text(item.option.promotion)
                                    .localized(weight: .regular, size: 12, color: .textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .visibility(item.option.promotion.isNotEmpty ? .visible : .gone)
                            }

                            LimitSpacer(8)

                            Image(
                                viewModel.selected?.option.name == item.option.name ?
                                    "iconSingleSelectionSelected24" : "iconSingleSelectionEmpty24")
                        }
                        .padding(.horizontal, 30)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.setSelected(item: item)
                        }

                        Separator()
                            .padding(.leading, 78)
                            .visibility(
                                index != viewModel.options.count - 1 ?
                                    .visible : .gone)
                    }
                    .id(CryptoSelectView.Identifier.selectorRows.rawValue)
                }
            }
            .padding(.vertical, 1)
            .onInspected(inspection, self)
        }
    }
}

struct CryptoSelectView_Previews: PreviewProvider {
    class ViewModel: CryptoDepositViewModelProtocol, ObservableObject {
        @Published private(set) var submitButtonDisable = true
        @Published private(set) var selected: CryptoDepositItemViewModel?

        lazy var options: [CryptoDepositItemViewModel] = [
            generateItem(type: .usdt, icon: "Main_USDT"),
            generateItem(type: .usdc, icon: "Main_USDC"),
            generateItem(type: .eth, icon: "Main_ETH")
        ]

        func generateItem(type: PaymentsDTO.TypeOptionsType, icon: String) -> CryptoDepositItemViewModel {
            .init(
                with:
                .init(
                    optionsId: "",
                    name: type.name,
                    promotion: "每笔 3 %红利,每日上限 500 元，1倍流水",
                    cryptoType: type),
                icon: icon,
                isSelected: false)
        }

        func fetchOptions() { }

        func setSelected(item: CryptoDepositItemViewModel?) {
            for element in options {
                element.isSelected = element.option == item?.option ? true : false
            }
            selected = item
        }

        func confirm() -> RxSwift.Single<CommonDTO.WebUrl> {
            .never()
        }
    }

    struct Preview: View {
        var body: some View {
            CryptoSelectView(
                viewModel: ViewModel(),
                playerConfig: FakePlayerConfiguration(.Vietnam()))
        }
    }

    static var previews: some View {
        Preview()
            .environment(\.playerLocale, .Vietnam())
    }
}
