import SwiftUI

struct TermsView<Presenter: TermsPresenter>: View {
  @StateObject var presenter: Presenter

  var body: some View {
    ScrollView(showsIndicators: false) {
      PageContainer {
        VStack(spacing: 24) {
          Topic()
          Sections()
        }
      }
    }
    .environmentObject(presenter)
    .padding(.horizontal, 30)
    .pageBackgroundColor(.greyScaleWhite)
    .frame(maxWidth: .infinity)
  }
}

// MARK: - Componment

extension TermsView {
  enum Identifier: String {
    case sections
  }

  struct Topic: View {
    @EnvironmentObject var presenter: Presenter

    var body: some View {
      VStack(alignment: .leading, spacing: 12) {
        Text(presenter.navigationTitle)
          .localized(
            weight: .semibold,
            size: 24,
            color: .greyScaleDefault)

        Text(presenter.description)
          .localized(
            weight: .regular,
            size: 14,
            color: .greyScaleDefault)
      }
    }
  }

  struct Sections: View {
    @EnvironmentObject var presenter: Presenter

    var inspection = Inspection<Self>()

    var body: some View {
      VStack(spacing: 0) {
        ForEach(presenter.dataSourceTerms.indices, id: \.self) { index in
          ExpandableBlock(
            title: presenter.dataSourceTerms[index].title,
            bottomLineVisible: index == presenter.dataSourceTerms.count - 1)
          {
            TermsView.Row(term: presenter.dataSourceTerms[index])
              .padding(.top, 16)
              .padding(.bottom, 30)
              .padding(.horizontal, 12)
          }
        }
        .id(TermsView.Identifier.sections.rawValue)
      }
      .onInspected(inspection, self)
    }
  }

  struct Row: View {
    let term: TermsOfService

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        Text(term.title)
          .localized(
            weight: .semibold,
            size: 14,
            color: .greyScaleDefault)

        Text(term.content)
          .localized(
            weight: .regular,
            size: 14,
            color: .textSecondary)
      }
    }
  }
}

struct TermsView_Previews: PreviewProvider {
  static var previews: some View {
    TermsView(presenter: ServiceTerms(barItemType: .back))
  }
}
