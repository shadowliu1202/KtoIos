import SwiftUI

struct VerifiedAlert: View {
    private let alertText: String

    init(_ alertText: String) {
        self.alertText = alertText
    }

    init(key: String) {
        self.alertText = Localize.string(key)
    }

    var body: some View {
        Text(alertText)
            .localized(weight: .regular, size: 14, color: .greyScaleWhite)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            .backgroundColor(.alert, cornerRadius: 8)
    }
}

struct VerifiedAlert_Previews: PreviewProvider {
    static var previews: some View {
        VerifiedAlert("Text")
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
