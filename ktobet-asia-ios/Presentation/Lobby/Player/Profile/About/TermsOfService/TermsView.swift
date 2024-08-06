import SwiftUI

struct TermsView: View {
    var presenter: any Terms

    var inspection = Inspection<Self>()

    enum Identifier: String {
        case sections
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            PageContainer {
                VStack(spacing: 0) {
                    VStack(alignment: .leading) {
                        Text(presenter.title)
                            .localized(weight: .semibold, size: 24, color: .greyScaleDefault)

                        LimitSpacer(12)

                        Text(presenter.description)
                            .localized(weight: .regular, size: 14, color: .greyScaleDefault)
                    }

                    LimitSpacer(24)

                    Separator()
                    ForEach(presenter.terms.indices, id: \.self) { index in
                        Item(
                            term: presenter.terms[index],
                            isLast: index == presenter.terms.count - 1
                        )
                        .id(TermsView.Identifier.sections.rawValue)
                    }
                }
            }
        }
        .onInspected(inspection, self)
        .padding(.horizontal, 30)
        .pageBackgroundColor(.greyScaleWhite)
        .frame(maxWidth: .infinity)
    }

    private struct Item: View {
        @State private var isExpand = false
        let term: TermItem
        let isLast: Bool

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(term.title)
                        .lineLimit(1)
                        .padding(.vertical, 12)
                    Spacer()

                    Image("termsArrowDown")
                        .frame(width: 16, height: 16)
                        .rotationEffect(Angle(degrees: isExpand ? 180 : 0))
                }
                Separator()

                if isExpand {
                    VStack(alignment: .leading) {
                        Text(term.title)
                            .localized(weight: .semibold, size: 14, color: .greyScaleDefault)

                        LimitSpacer(8)

                        Text(term.content)
                            .localized(weight: .regular, size: 14, color: .textSecondary)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 30)
                    .padding(.horizontal, 12)
                    if !isLast {
                        Separator()
                    }
                }
            }
            .onTapGestureForced {
                withAnimation {
                    isExpand.toggle()
                }
            }
        }
    }
}

struct TermsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsView(presenter: ServiceTerms())
    }
}
