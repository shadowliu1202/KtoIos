import Foundation
import sharedbu
import SwiftUI

struct LandingView<Content: View>: View {
    @StateObject var csViewModel: CustomerServiceViewModel
    @AppStorage(UserDefaults.Key.cultureCode.rawValue) var cultureCode: String?
    private let content: () -> Content

    init(csViewModel: CustomerServiceViewModel, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
        _csViewModel = .init(wrappedValue: csViewModel)
    }

    var body: some View {
        let currentLocale = if let cultureCode {
            Configuration.forceChinese ? SupportLocale.China() : SupportLocale.companion.create(language: cultureCode)
        } else {
            SupportLocale.Vietnam()
        }
        
        let fontName = KTOFontWeight.regular.fontString(currentLocale)
        
        navigation()
            .navigationViewManager()
            .navigationBarHidden(true)
            .navigationViewStyle(.stack)
            .environment(\.locale, .init(identifier: currentLocale.cultureCode()))
            .environment(\.font, .custom(fontName, size: 16))
            .environment(\.isCsProcessing, $csViewModel.isCsInProcess)
            .foregroundStyle(.textPrimary)
    }

    @ViewBuilder
    func navigation() -> some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content()
            }
        } else {
            // Navigation View has PopToRoot Bug on 16.0
            NavigationView {
                content()
            }
        }
    }
}

struct LandingViewScaffold_Previews: PreviewProvider {
    static var previews: some View {
        LandingViewScaffold(items: []) {
            VStack {
                Spacer()
                Text("KTO")
                    .font(weight: .medium, size: 16)
                    .foregroundStyle(.white)
                Spacer()
            }
        }
    }
}

struct LandingViewScaffold<Content: View, NavContent: NavItem>: View {
    private let content: Content
    let navItem: NavContent
    let items: [ItemViews]
    init(
        navItem: NavContent = .back(),
        items: [ItemViews] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.navItem = navItem
        self.items = items
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            content
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            LandingNavigationBar(navItem: navItem, items: items)
                .background(Color(.greyScaleDefault.withAlphaComponent(0.9)))
        }
        .navigationBarHidden(true)
        .backgroundColor(.greyScaleDefault, ignoresSafeArea: .all)
    }
}

enum ItemViews {
    case custom(NavigationItem<AnyView>)
    case cs(CsItem)
}

struct LandingNavigationBar: View {
    let navItem: any NavItem
    let items: [ItemViews]
    @Environment(\.dismiss) var dismiss
    @Environment(\.isCsProcessing) var inCs: Binding<Bool>
    init(navItem: any NavItem, items: [ItemViews]) {
        self.navItem = navItem
        self.items = items
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if !navItem.isEmpty {
                HStack(spacing: 0) {
                    AnyView(navItem)
                    Spacer()
                }
            }
            Image("KTO (D)")
                .frame(height: 16)
            HStack(alignment: .center, spacing: 0) {
                Spacer()
                ForEach(0 ..< items.count, id: \.self) { index in
                    switch items[index] {
                    case let .cs(view):
                        if !inCs.wrappedValue {
                            view
                            if index < items.count - 1 { divider() }
                        } else {
                            EmptyView()
                        }
                    case let .custom(view):
                        view
                        if index < items.count - 1 { divider() }
                    }
                }
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 30)
    }

    @ViewBuilder
    func divider() -> some View {
        Text("|")
            .font(weight: .semibold, size: 12)
            .foregroundStyle(.textSecondary)
            .padding(.horizontal, 8)
    }
}

struct LandingNavigationBar_Previews: PreviewProvider {
    static var previews: some View {
        LandingNavigationBar(navItem: EmptyItem(), items: [])
    }
}

struct NavigationItem<Content: View>: View {
    private let content: Content
    init(text: String, action: @escaping () -> Void) {
        let button = Button(
            action: action,
            label: {
                Text("\(text)")
                    .font(weight: .semibold, size: 16)
                    .foregroundStyle(.greyScaleIcon)
            }
        )
        content = AnyView(button) as! Content
    }

    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
    }
}

struct CsItem: View {
    @Environment(\.startCS) private var startCS
    var body: some View {
        Button(
            action: {
                startCS()
            },
            label: {
                Text("customerservice_action_bar_title")
                    .font(weight: .semibold, size: 16)
                    .foregroundStyle(.greyScaleIcon)
            }
        )
    }
}

extension ItemViews {
    static func cs() -> ItemViews {
        .cs(CsItem())
    }
}

protocol NavItem: View {
    associatedtype Label: View
    var action: () -> Void { get }
    func label() -> Label
    var isEmpty: Bool { get }
}

extension NavItem {
    var body: some View {
        Button(
            action: action,
            label: label
        )
        .buttonStyle(.plain)
    }

    var isEmpty: Bool { false }
}

struct BackItem: NavItem {
    @Environment(\.dismiss) var dismiss
    var action: () -> Void {
        { dismiss() }
    }

    func label() -> some View {
        Image("Back").frame(width: 24, height: 24)
    }
}

extension NavItem where Self == BackItem {
    static func back() -> BackItem {
        BackItem()
    }
}

struct CloseItem: NavItem {
    var action: () -> Void
    func label() -> some View {
        Image("Close").frame(width: 24, height: 24)
    }
}

extension NavItem where Self == CloseItem {
    static func close(action: @escaping () -> Void) -> CloseItem {
        CloseItem(action: action)
    }
}

struct EmptyItem: NavItem {
    var action: () -> Void = {}
    var isEmpty: Bool { true }
    func label() -> some View {
        EmptyView()
    }
}

extension NavItem where Self == EmptyItem {
    static func empty() -> EmptyItem {
        EmptyItem()
    }
}
