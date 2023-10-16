import sharedbu
import SwiftUI

struct CryptoGuideVNDView<ViewModel: CryptoGuideVNDViewModel>: View {
  @StateObject var viewModel: ViewModel

  private let supportLocale: SupportLocale = Injectable.resolve(LocalStorageRepository.self)!.getSupportLocale()

  var body: some View {
    ScrollView {
      PageContainer {
        VStack(spacing: 0) {
          header

          LimitSpacer(24)

          ForEach(viewModel.guidances, id: \.self) { guidance in
            ExpandableBlock(
              title: guidance.title,
              bottomLineVisible: guidance == viewModel.guidances.last,
              contentAlignment: .leading)
            {
              VStack(alignment: .leading, spacing: 16) {
                ForEach(guidance.links, id: \.self) { (guidanceLink: CryptoDepositGuidance.GuidanceLink) in
                  Text(guidanceLink.title)
                    .localized(weight: .semibold, size: 14, color: .primaryForLight)
                    .onTapGesture {
                      openTour(guidanceLink.link)
                    }
                }
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 16)
            }
          }
        }
        .padding(.horizontal, 30)
      }
    }
    .pageBackgroundColor(.greyScaleWhite)
    .environment(\.playerLocale, supportLocale)
    .onAppear {
      viewModel.getCryptoGuidance()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(Localize.string("cps_crypto_currency_guide_title"))
        .localized(weight: .semibold, size: 24, color: .greyScaleDefault)

      Text(Localize.string("cps_crypto_guidance_description"))
        .localized(weight: .regular, size: 14, color: .greyScaleDefault)
    }
  }

  private func openTour(_ urlString: String) {
    guard let url = URL(string: urlString) else { return }
    UIApplication.shared.open(url)
  }
}

struct CryptoGuideVNDView_Previews: PreviewProvider {
  static var previews: some View {
    CryptoGuideVNDView(viewModel: Injectable.resolve(CryptoGuideVNDViewModelImpl.self)!)
  }
}
