
import SwiftUI
import SharedBu

struct StarMergerView: View {
    @StateObject var viewModel: StarMergerViewModel
    let confirmButtonAction: (CommonDTO.WebPath?) -> Void
    
    init(viewModel: StarMergerViewModel, _ confirmButtonAction: @escaping (_ url: CommonDTO.WebPath?) -> Void) {
        self._viewModel = StateObject.init(wrappedValue: viewModel)
        self.confirmButtonAction = confirmButtonAction
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                self.starMergerTitle()
                HeightSpacer(16)
                VStack(alignment: .leading, spacing: 0) {
                    self.amountRange()
                    HeightSpacer(12)
                    CustomizedDivider()
                    HeightSpacer(12)
                    self.description()
                }
                .padding(.vertical, 30)
                .padding(.horizontal, 20)
                .customizedStrokeBorder(color: .primaryGray, cornerRadius: 14)
                HeightSpacer(30)
                self.starMergerHint()
                HeightSpacer(40)
                Button(Localize.string("common_submit2")) {
                    confirmButtonAction(viewModel.paymentLink)
                }
                .disabled(viewModel.paymentLink == nil ? true : false)
                .allowsHitTesting(viewModel.paymentLink == nil ? false : true)
                .buttonStyle(RedButtonStyle())
            }
            .padding(.horizontal, 30)
            .KTOPageSpacer()
        }
        .backgroundColor(.defaultGray)
        .ignoresSafeArea(.all, edges: .top)
    }
    
    private func starMergerTitle() -> some View {
        Text(Localize.string("cps_starmerger_title"))
            .fontAndColor(font: .custom("PingFangSC-Semibold", size: 24), color: .white)
    }
    
    private func amountRange() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localize.string("common_tip_title_warm"))
                .fontAndColor(font: .custom("PingFangSC-Regular", size: 14), color: .primaryGray)
            
            Text("\(viewModel.amountRange?.min.description() ?? "") RMB-\(viewModel.amountRange?.max.description() ?? "") RMB")
                .fontAndColor(font: .custom("PingFangSC-Medium", size: 14), color: .white)
        }
    }
    
    private func description() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localize.string("common_tip_title_warm"))
                .fontAndColor(font: .custom("PingFangSC-Regular", size: 14), color: .primaryGray)
            
            Text(Localize.string("cps_starmerger_description"))
                .fontAndColor(font: .custom("PingFangSC-Medium", size: 14), color: .white)
        }
    }
    
    private func starMergerHint() -> some View {
        Text(Localize.string("cps_starmerger_hint"))
            .fontAndColor(font: .custom("PingFangSC-Regular", size: 14), color: .primaryRed)
    }
}

//struct StarMergerView_Previews: PreviewProvider {
//    static var previews: some View {
//        StarMergerView(viewModel: DI.resolve(StarMergerViewModel.self)!, { _ in
//        })
//    }
//}
