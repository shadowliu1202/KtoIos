import SwiftUI
import SharedBu

struct PickList: View {
    @Binding var selectedItem: PaymentsDTO.Gateway?
    
    let items: [PaymentsDTO.Gateway]

    var body: some View {
        VStack(spacing: 0) {
            Separator(color: .gray3C3E40)
            
            ForEach(items, id: \.self) { item in
                gatewayCell(name: item.name, identity: item.identity, isLastCell: item == items.last)
            }
            
            Separator(color: .gray3C3E40)
        }
        .backgroundColor(.gray131313)
    }
    
    private func gatewayCell(name: String, identity: String, isLastCell: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Image("Default(32)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                LimitSpacer(16)
                Text(name)
                    .localized(weight: .medium, size: 14, color: .white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                LimitSpacer(8)
                Image(selectedItem == nil ? "iconSingleSelectionEmpty24": identity == selectedItem!.identity ? "iconSingleSelectionSelected24" : "iconSingleSelectionEmpty24")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 30)
            
            if !isLastCell {
                Separator(color: .gray3C3E40)
                    .padding(.leading, 78)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedItem = items.first(where: { gateway in
                gateway.identity == identity
            })!
        }
    }
}

struct PickList_Previews: PreviewProvider {
    struct Preview: View {
        let gateways = [PaymentsDTO.Gateway(identity: "70", name: "JinYiDigital", cash: CashType.Option(list: [], limitation: AmountRange.init(min: FiatFactory.shared.create(simpleName: "", amount: BignumBigDecimal.companion.fromInt(int: 200)), max: FiatFactory.shared.create(simpleName: "", amount: BignumBigDecimal.companion.fromInt(int: 200)))), remitType: PaymentsDTO.RemitType.normal, remitBank: [], verifier: CompositeVerification<RemitApplication, PaymentError>(), hint: "", isAccountNumberDenied: true, isInstructionDisplayed: true), PaymentsDTO.Gateway(identity: "20", name: "JinYiCrypto", cash: CashType.Option(list: [], limitation: AmountRange.init(min: FiatFactory.shared.create(simpleName: "", amount: BignumBigDecimal.companion.fromInt(int: 200)), max: FiatFactory.shared.create(simpleName: "", amount: BignumBigDecimal.companion.fromInt(int: 200)))), remitType: PaymentsDTO.RemitType.normal, remitBank: [], verifier: CompositeVerification<RemitApplication, PaymentError>(), hint: "", isAccountNumberDenied: true, isInstructionDisplayed: true)]
        
        @State private var selectedGateway: PaymentsDTO.Gateway? = PaymentsDTO.Gateway(identity: "70", name: "JinYiDigital", cash: CashType.Option(list: [], limitation: AmountRange.init(min: FiatFactory.shared.create(simpleName: "", amount: BignumBigDecimal.companion.fromInt(int: 200)), max: FiatFactory.shared.create(simpleName: "", amount: BignumBigDecimal.companion.fromInt(int: 200)))), remitType: PaymentsDTO.RemitType.normal, remitBank: [], verifier: CompositeVerification<RemitApplication, PaymentError>(), hint: "", isAccountNumberDenied: true, isInstructionDisplayed: true)
        
        var body: some View {
            PickList(selectedItem: $selectedGateway, items: gateways)
        }
    }
    
    static var previews: some View {
        VStack {
            Spacer()
            Preview()
            Spacer()
        }
        .pageBackgroundColor(.gray131313)
    }
}
