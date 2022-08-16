
import SwiftUI
import SharedBu

struct StarMergerView: View {
    @StateObject var viewModel: StarMergerViewModel
    let confirmButtonAction: (CommonDTO.WebPath?) -> Void
    
    init(viewModel: StarMergerViewModel, _ confirmButtonAction: @escaping (_ webPath: CommonDTO.WebPath?) -> Void) {
        self._viewModel = StateObject.init(wrappedValue: viewModel)
        self.confirmButtonAction = confirmButtonAction
    }
    
    var body: some View {
        ScrollView {
            PageContainer {
                VStack(spacing: 0) {
                    self.starMergerTitle()
                    LimitSpacer(16)
                    VStack(alignment: .leading, spacing: 0) {
                        self.amountRange()
                        LimitSpacer(12)
                        CustomizedDivider()
                        LimitSpacer(12)
                        self.description()
                    }
                    .padding(.vertical, 30)
                    .padding(.horizontal, 20)
                    .customizedStrokeBorder(color: .primaryGray, cornerRadius: 14)
                    LimitSpacer(30)
                    self.starMergerHint()
                    LimitSpacer(40)
                    Button(Localize.string("common_submit2")) {
                        confirmButtonAction(viewModel.paymentLink)
                    }
                    .buttonStyle(.confirmRed)
                    .disabled(viewModel.paymentLink == nil ? true : false)
                    .allowsHitTesting(viewModel.paymentLink == nil ? false : true)
                }
                .padding(.horizontal, 30)
            }
            .pageBackgroundColor(.defaultGray)
        }
    }
    
    private func starMergerTitle() -> some View {
        Text(Localize.string("cps_starmerger_title"))
            .customizedFont(fontWeight: .semibold, size: 24, color: .white)
    }
    
    private func amountRange() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localize.string("common_tip_title_warm"))
                .customizedFont(fontWeight: .regular, size: 14, color: .primaryGray)
            
            Text("\(viewModel.amountRange?.min.description() ?? "") RMB-\(viewModel.amountRange?.max.description() ?? "") RMB")
                .customizedFont(fontWeight: .medium, size: 14, color: .white)
        }
    }
    
    private func description() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(Localize.string("common_tip_title_warm"))
                .customizedFont(fontWeight: .regular, size: 14, color: .primaryGray)
            
            Text(Localize.string("cps_starmerger_description"))
                .customizedFont(fontWeight: .medium, size: 14, color: .white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func starMergerHint() -> some View {
        Text(Localize.string("cps_starmerger_hint"))
            .customizedFont(fontWeight: .regular, size: 14, color: .primaryRed)
    }
}

struct StarMergerView_Previews: PreviewProvider {
    static var previews: some View {
        StarMergerView(viewModel: DI.resolve(StarMergerViewModel.self)!, { _ in
        })
    }
}
