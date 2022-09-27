import SwiftUI

struct CryptoGuideVNDView<ViewModel: CryptoGuideVNDViewModel>: View {
    
    @StateObject var viewModel: ViewModel
    
    init(viewModel: ViewModel) {
        self._viewModel = StateObject.init(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            PageContainer {
                VStack(spacing: 0) {
                    header
                    
                    LimitSpacer(24)
                    
                    ForEach(0..<(viewModel.exchanges?.count ?? 0), id: \.self) { index in
                        if let exchange = viewModel.exchanges?[index] {
                            let isLastBlock = index == viewModel.exchanges!.count - 1 ? true : false
                            ExpandableBlock(title: exchange.name, isLastBlock: isLastBlock, contentAlignment: .leading) {
                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(0..<exchange.guides.count, id: \.self) { index in
                                        let guide = exchange.guides[index]
                                        Text(guide.name)
                                            .customizedFont(fontWeight: .semibold, size: 14, color: .primaryForLight)
                                            .onTapGesture { openTour(guide.link) }
                                    }
                                }
                                .padding(12)
                            }
                        }
                    }
                    
                }
                .padding(.horizontal, 30)
            }
        }
        .onAppear {
            viewModel.getCryptoGuidance()
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localize.string("cps_crypto_currency_guide_title"))
                .customizedFont(fontWeight: .semibold, size: 24, color: .defaultGray)
     
            Text(Localize.string("cps_crypto_guidance_description"))
                .customizedFont(fontWeight: .regular, size: 14, color: .defaultGray)
        }
    }
    
    private func openTour(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
    
}

class CryptoMarketExchange {
    var name: String
    var guides: [Guide]
    init(_ name: String, _ guides: [Guide] = []) {
        self.name = name
        self.guides = guides
    }
}

struct CryptoGuideVNDView_Previews: PreviewProvider {
    static var previews: some View {
        CryptoGuideVNDView(viewModel: DI.resolve(CryptoGuideVNDViewModelImpl.self)!)
    }
}
