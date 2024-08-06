import Foundation
import SwiftUI
import sharedbu

struct AccountTypePicker: View {
    @Binding var selection: AccountType
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AccountType.allCases) { item in
                PickerItem(type: item)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity)
                    .background(content: {
                        if selection == item {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.greyScaleIconDisable)
                                .matchedGeometryEffect(id: "Marker", in: namespace)
                        }
                    })
                    .padding(.vertical, 2)
                    .onTapGesture { if selection != item { selection = item } }
            }
        }
        .animation(.spring(duration: 0.25), value: selection)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func PickerItem(type: AccountType) -> some View {
        let key: LocalizedStringKey = switch type {
        case .phone:
            "common_mobile"
        case .email:
            "common_email"
        }
        Text(key)
            .localized(weight: .regular, size: 14, color: .white)
    }
}
