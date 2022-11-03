import SwiftUI
import SharedBu

struct StarMergerView<ViewModel: StarMergerViewModel>: View {
    var inspection = Inspection<Self>()
    enum Identifier: String {
        case submitButton
    }
    
    @StateObject var viewModel: ViewModel
    let confirmButtonAction: (CommonDTO.WebPath?) -> Void
    
    
    init(viewModel: ViewModel, _ confirmButtonAction: @escaping (_ webPath: CommonDTO.WebPath?) -> Void) {
        self._viewModel = StateObject.init(wrappedValue: viewModel)
        self.confirmButtonAction = confirmButtonAction
    }
    
    var body: some View {
        ScrollView {
            PageContainer {
                VStack(spacing: 0) {
                    starMergerInfo
                    
                    LimitSpacer(40)
                    
                    Button(Localize.string("common_submit2")) {
                        confirmButtonAction(viewModel.paymentLink)
                    }
                    .buttonStyle(.confirmRed)
                    .disabled(viewModel.paymentLink == nil ? true : false)
                    .id(Identifier.submitButton.rawValue)
                }
                .padding(.horizontal, 30)
            }
        }
        .pageBackgroundColor(.defaultGray)
        .onAppear {
            viewModel.getGatewayInformation()
        }
        .onReceive(inspection.notice) { self.inspection.visit(self, $0) }
    }
    
    @ViewBuilder
    private var starMergerInfo: some View {
        Text(Localize.string("cps_starmerger_title"))
            .customizedFont(fontWeight: .semibold, size: 24, color: .white)
        
        LimitSpacer(16)
        
        VStack(alignment: .leading, spacing: 0) {
            Text(Localize.string("common_tip_title_warm"))
                .customizedFont(fontWeight: .regular, size: 14, color: .primaryGray)
            Text("\(viewModel.amountRange?.min.description() ?? "") RMB-\(viewModel.amountRange?.max.description() ?? "") RMB")
                .customizedFont(fontWeight: .medium, size: 14, color: .white)
            LimitSpacer(12)
            CustomizedDivider()
            LimitSpacer(12)
            Text(Localize.string("common_tip_title_warm"))
                .customizedFont(fontWeight: .regular, size: 14, color: .primaryGray)
            Text(Localize.string("cps_starmerger_description"))
                .customizedFont(fontWeight: .medium, size: 14, color: .white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .customizedStrokeBorder(color: .primaryGray, cornerRadius: 14)
        
        LimitSpacer(30)
        
        Text(Localize.string("cps_starmerger_hint"))
            .customizedFont(fontWeight: .regular, size: 14, color: .primaryRed)
    }
}

struct StarMergerView_Previews: PreviewProvider {
    static var previews: some View {
        StarMergerView(viewModel: Injectable.resolve(StarMergerViewModelImpl.self)!, { _ in })
    }
}
