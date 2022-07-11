import SwiftUI
import SharedBu

struct WithdrawalCryptoDetailView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var data: WithdrawalDetail.Crypto
    
    private var finalInfoData: [(title: String, content: String)] {
        [(Localize.string("common_cps_final_crypto"), data.actualCryptoAmount.cryptoAmount.formatString()),
         (Localize.string("common_cps_final_rate"), data.actualCryptoAmount.exchangeRate.formatString()),
         (String(format: Localize.string("common_cps_final_amount"), "CNY"), data.actualCryptoAmount.cashAmount.description()),
         (Localize.string("common_cps_final_datetime"), data.approvedDate.toDateTimeString())]
    }
    
    private var applyInfoData: [(title: String, content: String)] {
        [(Localize.string("common_cps_apply_crypto"), data.requestCryptoAmount.cryptoAmount.formatString()),
         (Localize.string("common_cps_apply_rate"), data.requestCryptoAmount.exchangeRate.formatString()),
         (String(format: Localize.string("common_cps_apply_amount"), "CNY"), data.requestCryptoAmount.cashAmount.description()),
         (Localize.string("common_applytime"), data.record.createDate.toDateTimeString())]
    }
    
    private var remarkContent: [(date: String, content: String)] {
        var remarkString: [(date: String, content: String)] = []
        for history in data.statusChangeHistories {
            var contnetString = ""
            contnetString += history.remarkLevel1 + " > " +
            history.remarkLevel2 + " > " +
            history.remarkLevel3
            remarkString.append((history.createdDate.toDateTimeString(), contnetString))
        }
        
        return remarkString
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(Localize.string("withdrawal_detail_title"))
                        .foregroundColor(Color(UIColor.whiteFull))
                        .font(Font.custom("PingFangSC-Semibold", size: 24))
                        .padding(EdgeInsets(top: 78, leading: 0, bottom: 30, trailing: 0))
                    
                    Text("\(Localize.string("withdrawal_title")) - \(data.requestCryptoAmount.cryptoAmount.simpleName)")
                        .foregroundColor(Color(UIColor.whiteFull))
                        .font(Font.custom("PingFangSC-Medium", size: 16))
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                    
                    Text(Localize.string("common_cps_incomplete_field_placeholder_hint"))
                        .foregroundColor(Color(UIColor.textPrimaryDustyGray))
                        .font(Font.custom("PingFangSC-Regular", size: 14))
                }
                .padding(EdgeInsets(top: 0, leading: 30, bottom: 24, trailing: 0))
                
                Divider()
                    .frame(height: 1)
                    .background(Color(UIColor.dividerCapeCodGray2))
                
                VStack(alignment: .leading, spacing: 0) {
                    WithdrawalCryptoDetailRowView(title: Localize.string("balancelog_detail_id"), content: data.record.displayId, isShowBottomDivider: true)
                    WithdrawalCryptoDetailRowView(title: Localize.string("common_status"), content: StringMapper.sharedInstance.parse(data.record.transactionStatus, isPendingHold: data.isPendingHold, ignorePendingHold: true), isShowBottomDivider: true)
                }
                .padding(.horizontal, 30)
                
                Spacer().frame(height: 16)
                
                detailInfo
                
                VStack(spacing: 0) {
                    WithdrawalCryptoDetailRowView(title: String(format: Localize.string("common_cps_remitter"), Localize.string("cps_kto")), content: data.providerCryptoAddress, isShowBottomDivider: true)
                    WithdrawalCryptoDetailRowView(title: String(format: Localize.string("common_cps_payee"), Localize.string("common_player")), content: data.playerCryptoAddress, isShowBottomDivider: true)
                    
                    Spacer().frame(height: 8.5)
                    hashId
                    Spacer().frame(height: 8.5)
                    remark
                }.padding(.horizontal, 30)
                
                Spacer(minLength: 56)
                Divider()
                    .frame(height: 1)
                    .background(Color(UIColor.dividerCapeCodGray2))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .offset(x: 0, y: -60)
            
            Spacer(minLength: 96)
        }
        .background(Color(.black_two))
        .edgesIgnoringSafeArea(.all)
    }
    
    var detailInfo: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(Localize.string("common_cps_apply_info"))
                    .foregroundColor(Color(UIColor.textPrimaryDustyGray))
                    .font(Font.custom("PingFangSC-Medium", size: 16))
                    .padding(EdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 0))
                ForEach(applyInfoData.indices){ index in
                    WithdrawalCryptoDetailRowView(title: applyInfoData[index].title, content: applyInfoData[index].content, isShowBottomDivider: false)
                }
                
                Spacer().frame(height: 16)
                Divider()
                    .frame(height: 1)
                    .background(Color(UIColor.dividerCapeCodGray2))
                
                Text(Localize.string("common_cps_final_info"))
                    .foregroundColor(Color(UIColor.textPrimaryDustyGray))
                    .font(Font.custom("PingFangSC-Medium", size: 16))
                    .padding(EdgeInsets(top: 16, leading: 0, bottom: 0, trailing: 0))
                if TransactionStatus.approved == data.record.transactionStatus {
                    ForEach(finalInfoData.indices){ index in
                        WithdrawalCryptoDetailRowView(title: finalInfoData[index].title, content: finalInfoData[index].content, isShowBottomDivider: false, contentColor: index == 0 ? Color(UIColor.alert) : Color(.whiteFull))
                    }
                } else {
                    ForEach(finalInfoData.indices){ index in
                        WithdrawalCryptoDetailRowView(title: finalInfoData[index].title, content: "-", isShowBottomDivider: false)
                    }
                }
                
                Spacer().frame(height: 16)
            }
            .padding(.horizontal, 16)
            .border(Color(UIColor.dividerCapeCodGray2), width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
            
            Spacer().frame(height: 16)
            Divider()
                .frame(height: 1)
                .background(Color(UIColor.dividerCapeCodGray2))
        }
        .padding(.horizontal, 30)
    }
    
    var hashId: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localize.string("common_cps_hash_id"))
                .foregroundColor(Color(UIColor.textPrimaryDustyGray))
                .font(Font.custom("PingFangSC-Regular", size: 12))
            
            Spacer().frame(height: 2)
            
            if TransactionStatus.floating == data.record.transactionStatus {
                Button(action: {
                    guard let depositCryptoViewController = UIStoryboard(name: "Deposit", bundle: nil).instantiateViewController(withIdentifier: "DepositCryptoViewController") as? DepositCryptoViewController else { return }
                    depositCryptoViewController.displayId = data.record.displayId
                    NavigationManagement.sharedInstance.pushViewController(vc: depositCryptoViewController)
                }) {
                    Text(Localize.string("common_cps_submit_hash_id_to_complete"))
                        .foregroundColor(Color(UIColor.redForDarkFull))
                        .font(Font.custom("PingFangSC-Regular", size: 16))
                        .underline()
                }
            } else {
                Text(data.hashId.isEmpty ? "-" : data.hashId)
                    .foregroundColor(Color(UIColor.whiteFull))
                    .font(Font.custom("PingFangSC-Regular", size: 16))
            }
            
            Spacer().frame(height: 8.5)
            Divider()
                .frame(height: 1)
                .background(Color(UIColor.dividerCapeCodGray2))
        }
    }
    
    var remark: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localize.string("common_remark"))
                .foregroundColor(Color(UIColor.textPrimaryDustyGray))
                .font(Font.custom("PingFangSC-Regular", size: 12))
            
            if !remarkContent.isEmpty {
                ForEach(remarkContent.indices) { index in
                    Text(remarkContent[index].date)
                        .foregroundColor(Color(UIColor.textPrimaryDustyGray))
                        .font(Font.custom("PingFangSC-Regular", size: 12))
                    
                    Text(remarkContent[index].content)
                        .foregroundColor(Color(UIColor.whiteFull))
                        .font(Font.custom("PingFangSC-Regular", size: 16))
                }
            } else {
                Text("-")
                    .foregroundColor(Color(UIColor.whiteFull))
                    .font(Font.custom("PingFangSC-Regular", size: 16))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WithdrawalCryptoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let previewData = WithdrawalCryptoPreviewData()
            WithdrawalCryptoDetailView(data: previewData.withdrawalDetail)
                .previewLayout(.fixed(width: 380, height: 1600))
                .previewDevice("iPhone 13 mini")
            WithdrawalCryptoDetailView(data: previewData.withdrawalDetail)
                .previewDevice("iPhone 13 mini")
        }
    }
}

class WithdrawalCryptoPreviewData {
    var withdrawalRecord: WithdrawalRecord {
        WithdrawalRecord(transactionTransactionType: TransactionType.cryptowithdrawal, displayId: "displayId", transactionStatus: TransactionStatus.approved, createDate: Date().toUTCOffsetDateTime(), cashAmount: AccountCurrency(tempAmount: BignumBigDecimal.companion.fromInt(int: 200), simpleName: "", symbol: ""), isPendingHold: true, groupDay: SharedBu.LocalDate.init(year: 1999, month: SharedBu.Month.october, dayOfMonth: 1))
    }
    
    var requestCryptoAmount: CryptoExchangeRecord {
        let cryptoType = SupportCryptoType.valueOf("ETH")
        let locale = SupportLocale.companion.create(language: "zh-cn")
        let exchangeRate = CryptoExchangeFactory.init().create(from: cryptoType, to: locale, exRate: "0")
        return CryptoExchangeRecord (cryptoAmount: 0.toCryptoCurrency(SupportCryptoType.valueOf("ETH")), exchangeRate: exchangeRate, cashAmount: 3600.toAccountCurrency(), date: Date().toUTCOffsetDateTime())
    }
    
    var actualCryptoAmount: CryptoExchangeRecord {
        let cryptoType = SupportCryptoType.valueOf("ETH")
        let locale = SupportLocale.companion.create(language: "zh-cn")
        let exchangeRate = CryptoExchangeFactory.init().create(from: cryptoType, to: locale, exRate: "0")
        return CryptoExchangeRecord (cryptoAmount: 10.toCryptoCurrency(SupportCryptoType.valueOf("ETH")), exchangeRate: exchangeRate, cashAmount: 2030.toAccountCurrency(), date: Date().toUTCOffsetDateTime())
    }
    
    var statusChangeHistory: SharedBu.Transaction.StatusChangeHistory {
        SharedBu.Transaction.StatusChangeHistory(createdDate: Date().toUTCOffsetDateTime(), imageIds: [PortalImage.Public(imageId: "", fileName: "", host: "")], remarkLevel1: "remarkLevel1", remarkLevel2: "remarkLevel2", remarkLevel3: "remarkLevel3")
    }
    
    var withdrawalDetail: WithdrawalDetail.Crypto {
        WithdrawalDetail.Crypto(record: withdrawalRecord,
                                isBatched: true,
                                isPendingHold: true,
                                statusChangeHistories: [statusChangeHistory],
                                updatedDate: Date().toUTCOffsetDateTime(),
                                requestCryptoAmount: requestCryptoAmount,
                                actualCryptoAmount: actualCryptoAmount,
                                playerCryptoAddress: "playerCryptoAddress",
                                providerCryptoAddress: "providerCryptoAddress",
                                approvedDate: Date().toUTCOffsetDateTime(),
                                hashId: "hashId")
    }
}
