import SwiftUI
import SharedBu

struct WithdrawalTextRowView: View {
    var title: String = ""
    var content: String = ""
    var isRemark: Bool = false
    var isFlooting: Bool = false
    var data: WithdrawalDetail.Crypto?
    
    init(title: String, content: String, isFlooting: Bool = false, data: WithdrawalDetail.Crypto? = nil) {
        self.title = title
        self.data = data
        self.content = content
        self.isFlooting = isFlooting
    }
    
    init(data: WithdrawalDetail.Crypto?, title: String = "", isRemark: Bool = false) {
        self.data = data
        self.title = title
        self.isRemark = isRemark
    }
    
    var body: some View {
        Text(title)
            .foregroundColor(Color(UIColor.textPrimaryDustyGray))
            .font(Font.custom("PingFangSC-Regular", size: 12))
        Spacer().frame(height: 2)
        
        if !isRemark {
            Text(content)
                .foregroundColor(Color(UIColor.whiteFull))
                .font(Font.custom("PingFangSC-Regular", size: 16))
            if isFlooting && TransactionStatus.floating == data?.record.transactionStatus {
                Spacer().frame(height: 2)
                Button(action: {
                    guard let depositCryptoViewController = UIStoryboard(name: "Deposit", bundle: nil).instantiateViewController(withIdentifier: "DepositCryptoViewController") as? DepositCryptoViewController else { return }
                    depositCryptoViewController.displayId = data?.record.displayId
                    NavigationManagement.sharedInstance.pushViewController(vc: depositCryptoViewController)
                }) {
                    Text(Localize.string("common_cps_submit_hash_id_to_complete"))
                        .foregroundColor(Color(UIColor.redForDarkFull))
                        .font(Font.custom("PingFangSC-Regular", size: 16))
                        .underline()
                }
            }
        } else {
            if let data = data {
                ForEach(0..<data.statusChangeHistories.count) { index in
                    Text(data.updatedDate.formatDateToStringToSecond())
                        .foregroundColor(Color(UIColor.textPrimaryDustyGray))
                        .font(Font.custom("PingFangSC-Regular", size: 12))
                    Spacer().frame(height: 2)
                    Text(data.statusChangeHistories[index].remarkLevel1 + " > " +
                            data.statusChangeHistories[index].remarkLevel2 + " > " +
                            data.statusChangeHistories[index].remarkLevel3)
                        .foregroundColor(Color(UIColor.whiteFull))
                        .font(Font.custom("PingFangSC-Regular", size: 16))
                    Spacer().frame(height: 18)
                }
            }
            
            Spacer().frame(height: 63)
        }
    }
    
    func getTranctionInfoContent(group: Int, row: Int) -> String {
        switch group {
        case 0:
            return applyContentString()?[row] ?? "-"
        case 1:
            if data?.record.transactionStatus == TransactionStatus.approved {
                return finalContentString()?[row] ?? "-"
            } else {
                return "-"
            }
        default:
            return ""
        }
    }
    
    func getFinalConentColor(group: Int, row: Int) -> Color {
        if let finalContentString = finalContentString()?[row] {
            if group == 1 && row == 0 && finalContentString != "0.00000000" {
                return Color(UIColor.alert)
            } else {
                return Color(UIColor.whiteFull)
            }
        } else {
            return Color(UIColor.whiteFull)
        }
    }
    
    private func applyContentString() -> [String]? {
        guard let data = data else { return nil }
        return [data.requestCryptoAmount.cryptoAmount.cryptoAmount.currencyFormatWithoutSymbol(precision: 8, maximumFractionDigits: 8),
                data.requestCryptoAmount.exchangeRate.rate.currencyFormatWithoutSymbol(precision: 6, maximumFractionDigits: 8),
                data.requestCryptoAmount.cashAmount.amount.currencyFormatWithoutSymbol(precision: 2),
                data.record.createDate.formatDateToStringToSecond()]
    }
    
    private func finalContentString() -> [String]? {
        guard let data = data else { return nil }
        return [data.actualCryptoAmount.cryptoAmount.cryptoAmount.currencyFormatWithoutSymbol(precision: 8, maximumFractionDigits: 8),
                data.actualCryptoAmount.exchangeRate.rate.currencyFormatWithoutSymbol(precision: 6, maximumFractionDigits: 8),
                data.actualCryptoAmount.cashAmount.amount.currencyFormatWithoutSymbol(precision: 2),
                data.updatedDate.formatDateToStringToSecond()]
    }
}

struct WithdrawalCryptoDetailView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var data: WithdrawalDetail.Crypto?
        
    var textView: WithdrawalTextRowView{ WithdrawalTextRowView(data: data) }
    var titleStrings = [Localize.string("balancelog_detail_id"), Localize.string("activity_status"), String(format: Localize.string("common_cps_remitter"), Localize.string("cps_kto")), String(format: Localize.string("common_cps_payee"), Localize.string("common_player")), Localize.string("common_cps_hash_id"), Localize.string("common_remark")]
    private let applyTitleStrings =
        [Localize.string("common_cps_apply_crypto"),
         Localize.string("common_cps_apply_rate"),
         String(format: Localize.string("common_cps_apply_amount"), "CNY"),
         Localize.string("common_applytime")]
    
    private let finalTitleString = [Localize.string("common_cps_final_info"),
                                    Localize.string("common_cps_final_rate"),
                                    String(format: Localize.string("common_cps_final_amount"), "CNY"),
                                    Localize.string("common_cps_final_datetime")
    ]
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Spacer()
                }
                Text(Localize.string("deposit_detail_title"))
                    .foregroundColor(Color(UIColor.whiteFull))
                    .font(Font.custom("PingFangSC-Semibold", size: 24))
                Spacer().frame(height: 22)
                Text("\(Localize.string("withdrawal_title")) - \(Localize.string("common_ethereum"))")
                    .foregroundColor(Color(UIColor.whiteFull))
                    .font(Font.custom("PingFangSC-Medium", size: 16))
                Text(Localize.string("common_cps_incomplete_field_placeholder_hint"))
                    .foregroundColor(Color(UIColor.textPrimaryDustyGray))
                    .font(Font.custom("PingFangSC-Regular", size: 14))
            }.padding(.leading, 30).padding(.bottom, 24).padding(.trailing, 30)
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading:
                                    Button(action: {
                                        NavigationManagement.sharedInstance.popViewController()
                                        self.presentationMode.wrappedValue.dismiss()
                                    }) {
                                        SwiftUI.Image("Back")
                                    }
            )
            Divider().frame(height: 1).background(Color(UIColor.dividerCapeCodGray2))
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                }
                ForEach(0 ..< 2) { index in
                    WithdrawalTextRowView(title: titleStrings[index], content: contentStrings()?[index] ?? "", isFlooting: index == 1, data: data)
                    Divider().frame(height: 1).background(Color(UIColor.dividerCapeCodGray2))
                }
            }
            .padding(.leading, 30.0).padding(.trailing, 30)
            Spacer().frame(height: 16)
            Group {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Spacer()
                    }
                    ForEach(0..<2) { groupIndex in
                        Spacer().frame(height: groupIndex == 1 ? 8 : 0)
                        Text(groupIndex == 0 ? Localize.string("common_cps_apply_info") : Localize.string("common_cps_final_info"))
                            .foregroundColor(Color(UIColor.textPrimaryDustyGray))
                            .font(Font.custom("PingFangSC-Medium", size: 16))
                        ForEach(0..<4) { i in
                            Text(groupIndex == 0 ? applyTitleStrings[i] : finalTitleString[i])
                                .foregroundColor(Color(UIColor.textPrimaryDustyGray))
                                .font(Font.custom("PingFangSC-Regular", size: 12))
                            Text(textView.getTranctionInfoContent(group: groupIndex, row: i))
                                .foregroundColor(textView.getFinalConentColor(group: groupIndex, row: i))
                                .font(Font.custom("PingFangSC-Regular", size: 16))
                        }
                        
                        if groupIndex == 0 {
                            Divider().frame(height: 1).background(Color(UIColor.dividerCapeCodGray2))
                        }
                    }
                }
                .padding(16).padding(.top, -8)
                .border(Color(UIColor.dividerCapeCodGray2), width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            }.padding(.leading, 30.0).padding(.trailing, 30)
            VStack(alignment: .leading) {
                HStack {
                    Spacer()
                }
                ForEach(2 ..< 6) { index in
                    Divider().frame(height: 1).background(Color(UIColor.dividerCapeCodGray2))
                    if index != 5 {
                        WithdrawalTextRowView(title: titleStrings[index], content: contentStrings()?[index] ?? "")
                    } else {
                        WithdrawalTextRowView(data: data,title: titleStrings[index], isRemark: true)
                    }
                }
            }
            .padding(.leading, 30.0).padding(.trailing, 30)
            Divider().frame(height: 1).background(Color(UIColor.dividerCapeCodGray2))
            Spacer().frame(height: 96)
        }
        .background(Color(UIColor.black_two).edgesIgnoringSafeArea(.all))

    }
    
    private func contentStrings() -> [String]? {
        guard let data = self.data else {return nil}
        return [data.record.displayId,
                StringMapper.sharedInstance.parse(data.record.transactionStatus, isPendingHold: data.isPendingHold, ignorePendingHold: true),
                "-",
                data.playerCryptoAddress,
                data.hashId.isEmpty ? "-" : data.hashId, ""]
    }
}

struct WithdrawalCryptoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        WithdrawalCryptoDetailView(data: nil)
    }
}
