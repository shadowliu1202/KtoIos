import Foundation
import SwiftUI

struct LandingServiceTermView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .topLeading) {
            TermsView(presenter: ServiceTerms())
        }
        .safeAreaInset(edge: .top) { NavigationBar() }
        .navigationBarHidden(true)
        .backgroundColor(.white, ignoresSafeArea: .all)
    }

    @ViewBuilder
    private func NavigationBar() -> some View {
        HStack {
            Button { dismiss() }
                label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                }

            Spacer()
        }
        .frame(height: 56)
        .padding(.horizontal, 30)
        .background(Color(.greyScaleDefault.withAlphaComponent(0.9)))
    }
}

struct ServiceTermsView_Previews: PreviewProvider {
    static var previews: some View {
        LandingServiceTermView()
    }
}
