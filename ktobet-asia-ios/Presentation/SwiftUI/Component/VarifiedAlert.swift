import SwiftUI

struct VerifiedAlert: View {
    private let key: LocalizedStringKey

    init(key: LocalizedStringKey) {
        self.key = key
    }

    var body: some View {
        Text(key)
            .font(size: 14)
            .foregroundStyle(.greyScaleWhite)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            .backgroundColor(.alert, cornerRadius: 8)
    }
}

struct VerifiedAlert_Previews: PreviewProvider {
    static var previews: some View {
        VerifiedAlert(key: "common_invalid")
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
