import SwiftUI
import SharedBu

struct textRowView: View {
    var title: String = ""
    var content: String = ""
    var isRemark: Bool = false
    var isFlooting: Bool = false
    var data: PaymentLogDTO.CryptoLog?
    
    init(title: String, content: String, isFlooting: Bool = false, data: PaymentLogDTO.CryptoLog? = nil) {
        self.title = title
        self.data = data
        self.content = content
        self.isFlooting = isFlooting
    }
    
    init(data: PaymentLogDTO.CryptoLog?, title: String = "", isRemark: Bool = false) {
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
            if isFlooting && PaymentStatus.floating == data?.log.status {
                Spacer().frame(height: 2)
                Button(action: {
                    guard let depositCryptoViewController = UIStoryboard(name: "Deposit", bundle: nil).instantiateViewController(withIdentifier: "DepositCryptoViewController") as? DepositCryptoViewController else { return }
                    depositCryptoViewController.updateUrl = data?.updateUrl
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
                let histories: [UpdateHistory] = data.updateHistories
                ForEach(0..<histories.count, id: \.self) { index in
                    Text(data.log.updateDate.toDateTimeString())
                        .foregroundColor(Color(UIColor.textPrimaryDustyGray))
                        .font(Font.custom("PingFangSC-Regular", size: 12))
                    Spacer().frame(height: 2)
                    Text(histories[index].remarkLevel1 + " > " +
                         histories[index].remarkLevel2 + " > " +
                         histories[index].remarkLevel3)
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
            if applyContentString()?[row] != "0" {
                return applyContentString()?[row] ?? ""
            } else {
                return "-"
            }
        case 1:
            if let data = data, data.isTransactionComplete == true {
               return finalContentString()?[row] ?? ""
            } else {
                return "-"
            }
        default:
            return ""
        }
    }
    
    func getFinalConentColor(group: Int, row: Int) -> Color {
        if group == 1 && row == 0 && finalContentString()?[row] != "0" {
            return Color(UIColor.alert)
        } else {
            return Color(UIColor.whiteFull)
        }
    }
    
    private func applyContentString() -> [String]? {
        guard let data = data, let memo = data.processingMemo.request else { return nil }
        return [memo.fromCrypto.formatString(),
                memo.rate.formatString(),
                memo.toFiat.formatString(),
                data.log.createdDate.toDateTimeString()]
    }
    
    private func finalContentString() -> [String]? {
        guard let data = data, let memo = data.processingMemo.actual else { return nil }
        return [memo.fromCrypto.formatString(),
                memo.rate.formatString(),
                memo.toFiat.formatString(),
                memo.date.toDateTimeString()]
    }
}

struct DepositCryptoDetailView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State var data: PaymentLogDTO.CryptoLog?
        
    var textView: textRowView{ textRowView(data: data) }
    var titleStrings = [Localize.string("balancelog_detail_id"), Localize.string("activity_status"), String(format: Localize.string("common_cps_remitter"), Localize.string("common_player")), String(format: Localize.string("common_cps_payee"), Localize.string("cps_kto")), Localize.string("common_cps_hash_id"), Localize.string("common_remark")]
    private let applyTitleStrings =
        [Localize.string("common_cps_apply_crypto"),
         Localize.string("common_cps_apply_rate"),
         String(format: Localize.string("common_cps_apply_amount"), "CNY"),
         Localize.string("common_applytime")]
    
    private let finalTitleString = [Localize.string("common_cps_final_crypto"),
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
                Text("\(Localize.string("deposit_title")) - \(data?.processingMemo.request?.fromCrypto.simpleName ?? "")")
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
                    textRowView(title: titleStrings[index], content: contentStrings()?[index] ?? "", isFlooting: index == 1, data: data)
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
                        textRowView(title: titleStrings[index], content: contentStrings()?[index] ?? "")
                    } else {
                        textRowView(data: data,title: titleStrings[index], isRemark: true)
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
        return [data.log.displayId,
                data.log.status.toLogString(),
                "-",
                data.processingMemo.toAddress,
                data.processingMemo.hashId.isEmpty ? "-" : data.processingMemo.hashId, ""]
    }
}

struct DepositCryptoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DepositCryptoDetailView(data: nil)
    }
}
