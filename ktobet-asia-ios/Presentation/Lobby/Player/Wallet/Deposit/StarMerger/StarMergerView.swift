import sharedbu
import SwiftUI

struct StarMergerView<ViewModel: StarMergerViewModel>: View {
  var inspection = Inspection<Self>()
  enum Identifier: String {
    case submitButton
  }

  @StateObject var viewModel: ViewModel
  let confirmButtonAction: (CommonDTO.WebPath?) -> Void

  init(viewModel: ViewModel, _ confirmButtonAction: @escaping (_ webPath: CommonDTO.WebPath?) -> Void) {
    self._viewModel = StateObject(wrappedValue: viewModel)
    self.confirmButtonAction = confirmButtonAction
  }

  var body: some View {
    ScrollView {
      PageContainer {
        VStack(spacing: 0) {
          starMergerInfo

          LimitSpacer(40)
          
          PrimaryButton(
            title: Localize.string("common_submit2"),
            action: {
              confirmButtonAction(viewModel.paymentLink)
            })
            .disabled(viewModel.paymentLink == nil ? true : false)
            .id(Identifier.submitButton.rawValue)
        }
        .padding(.horizontal, 30)
      }
    }
    .onPageLoading(viewModel.amountRange == nil || viewModel.paymentLink == nil)
    .pageBackgroundColor(.greyScaleDefault)
    .onAppear {
      viewModel.getGatewayInformation()
    }
    .onReceive(inspection.notice) { self.inspection.visit(self, $0) }
  }

  @ViewBuilder private var starMergerInfo: some View {
    Text(Localize.string("cps_starmerger_title"))
      .localized(weight: .semibold, size: 24, color: .white)

    LimitSpacer(16)

    VStack(alignment: .leading, spacing: 0) {
      Text(Localize.string("common_tip_title_warm"))
        .localized(weight: .regular, size: 14, color: .textPrimary)
      Text("\(viewModel.amountRange?.min.description() ?? "") RMB-\(viewModel.amountRange?.max.description() ?? "") RMB")
        .localized(weight: .medium, size: 14, color: .white)
      LimitSpacer(12)
      Separator()
      LimitSpacer(12)
      Text(Localize.string("common_tip_title_warm"))
        .localized(weight: .regular, size: 14, color: .textPrimary)
      Text(Localize.string("cps_starmerger_description"))
        .localized(weight: .medium, size: 14, color: .white)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, 30)
    .padding(.horizontal, 20)
    .stroke(color: .textPrimary, cornerRadius: 14)

    LimitSpacer(30)

    Text(Localize.string("cps_starmerger_hint"))
      .localized(weight: .regular, size: 14, color: .primaryDefault)
  }
}

struct StarMergerView_Previews: PreviewProvider {
  class ViewModel: ObservableObject, StarMergerViewModel {
    var amountRange: AmountRange? = .init(min: "100".toAccountCurrency(), max: "1000".toAccountCurrency())

    var paymentLink: CommonDTO.WebPath? = .init(path: "123")

    func getGatewayInformation() { }
  }

  static var previews: some View {
    VStack {
      StarMergerView(viewModel: ViewModel(), { _ in })
    }
  }
}
