import SwiftUI

struct JinYiDigitalGuideView: View {
    let highlightWords = [Localize.string("jinyidigital_desciption_highlight_1"), Localize.string("jinyidigital_desciption_highlight_2"), Localize.string("jinyidigital_desciption_highlight_3"), Localize.string("jinyidigital_desciption_highlight_4")]
    
    var body: some View {
        ScrollView {
            PageContainer {
                VStack(spacing: 0) {
                    header
                    
                    LimitSpacer(32)
                    
                    ExpandableBlock(title: Localize.string("jinyidigital_wallet_categories")) {
                        VStack(spacing: 24) {
                            walletType1
                            walletType2
                            walletType3
                            walletType4
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 32)
                        .padding(.horizontal, 12)
                    }
                    
                    ExpandableBlock(title: Localize.string("jinyidigital_wallet_application_requirements"), isLastBlock: true) {
                        VStack(alignment: .leading, spacing: 24) {
                            walletRequirement1
                            walletRequirement2
                            walletRequirement3
                            walletRequirement4
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 12)
                    }
                }
            }
            .padding(.horizontal, 30)
        }
        .pageBackgroundColor(.white)
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localize.string("jinyidigital_instructions_title"))
                .customizedFont(fontWeight: .semibold, size: 24, color: .defaultGray)
            
            Text(Localize.string("jinyidigital_instructions_download"))
                .customizedFont(fontWeight: .regular, size: 14, color: .defaultGray)
            
            ZStack {
                Rectangle()
                    .foregroundColor(.lightGray)
                    .frame(height: 160)
                
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(.white)
                    .shadow(color: .shadowBlack, radius: 4, x: 0, y: 2)
                    .padding(30)
                    .overlay(
                        HStack(spacing: 10) {
                            Image("JinYiPAY")
                                .frame(width: 48, height: 48)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Localize.string("jinyidigital_app_title"))
                                    .customizedFont(fontWeight: .semibold, size: 12, color: .black)
                                Text(Localize.string("jinyidigital_app_category"))
                                    .customizedFont(fontWeight: .semibold, size: 12, color: .gray2)
                            }
                        }
                            .padding(.horizontal, 38)
                            .padding(.vertical, 26)
                    )
            }
        }
    }
    
    private var walletType1: some View {
        walletTypeTemplate(typeName: Localize.string("jinyidigital_first_wallet"), requirement: Localize.string("jinyidigital_first_wallet_requirements"), tradeLimit: [Localize.string("jinyidigital_first_wallet_balance_maximum"), Localize.string("jinyidigital_first_wallet_single_transfer_upper_limit"), Localize.string("jinyidigital_first_wallet_daily_transfer_upper_limit"), Localize.string("jinyidigital_first_wallet_annually_transfer_upper_limit")])
    }
    
    private var walletType2: some View {
        walletTypeTemplate(typeName: Localize.string("jinyidigital_second_wallet"), requirement: Localize.string("jinyidigital_second_wallet_requirements"), tradeLimit: [Localize.string("jinyidigital_second_wallet_balance_maximum"), Localize.string("jinyidigital_second_wallet_single_transfer_upper_limit"), Localize.string("jinyidigital_second_wallet_daily_transfer_upper_limit"), Localize.string("jinyidigital_second_wallet_annually_transfer_upper_limit")])
    }
    
    private var walletType3: some View {
        walletTypeTemplate(typeName: Localize.string("jinyidigital_third_wallet"), requirement: Localize.string("jinyidigital_third_wallet_requirements"), tradeLimit: [Localize.string("jinyidigital_third_wallet_balance_maximum"), Localize.string("jinyidigital_third_wallet_single_transfer_upper_limit"), Localize.string("jinyidigital_third_wallet_daily_transfer_upper_limit"), Localize.string("jinyidigital_third_wallet_annually_transfer_upper_limit")])
    }
    
    private var walletType4: some View {
        walletTypeTemplate(typeName: Localize.string("jinyidigital_fourth_wallet"), requirement: Localize.string("jinyidigital_fourth_wallet_requirements"), tradeLimit: [Localize.string("jinyidigital_fourth_wallet_balance_maximum"), Localize.string("jinyidigital_fourth_wallet_single_transfer_upper_limit"), Localize.string("jinyidigital_fourth_wallet_daily_transfer_upper_limit"), Localize.string("jinyidigital_fourth_wallet_annually_transfer_upper_limit")])
    }
    
    private var walletRequirement1: some View {
        walletRequirementTemplate(title: Localize.string("jinyidigital_first_wallet"), content: Localize.string("jinyidigital_first_wallet_requirements_description"))
    }
    
    private var walletRequirement2: some View {
        walletRequirementTemplate(title: Localize.string("jinyidigital_second_wallet"), content: Localize.string("jinyidigital_second_wallet_requirements_description"))
    }
    
    private var walletRequirement3: some View {
        walletRequirementTemplate(title: Localize.string("jinyidigital_third_wallet"), content: Localize.string("jinyidigital_third_wallet_requirements_description"))
    }
    
    private var walletRequirement4: some View {
        walletRequirementTemplate(title: Localize.string("jinyidigital_fourth_wallet"), content: Localize.string("jinyidigital_fourth_wallet_requirements_description"))
    }
    
    private func walletTypeTemplate(typeName: String, requirement: String, tradeLimit: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            bulletText(typeName)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(Localize.string("jinyidigital_application_requirements"))
                    .customizedFont(fontWeight: .semibold, size: 14, color: .secondary)
                
                Text(requirement)
                    .customizedFont(fontWeight: .regular, size: 14, color: .secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(Localize.string("jinyidigital_application_limits"))
                    .customizedFont(fontWeight: .semibold, size: 14, color: .secondary)
                
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text(Localize.string("jinyidigital_balance_maximum"))
                            .padding(.horizontal, 18.75)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                        Text(tradeLimit[0])
                            .padding(.horizontal, 18.75)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                    }
                    .backgroundColor(.darkGray)
                    
                    HStack(spacing: 0) {
                        Text(Localize.string("jinyidigital_single_transfer_upper_limit"))
                            .padding(.horizontal, 18.75)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                        Text(tradeLimit[1])
                            .padding(.horizontal, 18.75)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                    }
                    .backgroundColor(.white)
                    
                    HStack(spacing: 0) {
                        Text(Localize.string("jinyidigital_daily_transfer_upper_limit"))
                            .padding(.horizontal, 18.75)
                            .padding(.vertical, 6)
                            .fixedSize()
                            .frame(maxWidth: .infinity)
                        Text(tradeLimit[2])
                            .padding(.horizontal, 18.75)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                    }
                    .backgroundColor(.darkGray)
                    
                    HStack(spacing: 0) {
                        Text(Localize.string("jinyidigital_annually_transfer_upper_limit"))
                            .padding(.horizontal, 18.75)
                            .padding(.vertical, 6)
                            .fixedSize()
                            .frame(maxWidth: .infinity)
                        Text(tradeLimit[3])
                            .padding(.horizontal, 18.75)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                    }
                    .backgroundColor(.white)
                }
                .customizedFont(fontWeight: .medium, size: 12, color: .secondary)
            }
        }
    }
    
    private func bulletText(_ text: String) -> some View {
        HStack(spacing: 0) {
            Circle()
                .foregroundColor(.black)
                .frame(width: 5, height: 5)
                .padding(.horizontal, 5)
            
            Text(text)
                .customizedFont(fontWeight: .semibold, size: 14, color: .defaultGray)
        }
    }
    
    private func walletRequirementTemplate(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            bulletText(title)
            
            generateHighlightSentence(fullSentence: content, generalColor: .secondary, highlightWords: highlightWords, highlightColor: .primaryRed)
                .customizedFont(fontWeight: .regular, size: 14)
        }
    }
}

struct JinYiDigitalGuideView_Previews: PreviewProvider {
    static var previews: some View {
        JinYiDigitalGuideView()
            .previewLayout(.fixed(width: 360, height: 2000))
    }
}
