import SwiftUI

@available(*, deprecated, message: "Waiting for refactor.")
struct LogSections<T: LogRowModel>: View {
  struct Model {
    let title: String
    let items: [T]
  }

  enum Identifier {
    case sectionHeader(at: Int)
    case section(at: Int)
    case emptyStateView

    var rawValue: String { "\(self)" }
  }

  @EnvironmentObject var safeAreaMonitor: SafeAreaMonitor

  let models: [Model]?
  let isPageLoading: Bool

  var onRowSelected: ((T) -> Void)?

  var body: some View {
    if let sections = models {
      if !sections.isEmpty {
        VStack {
          ForEach(sections.indices, id: \.self) { sectionIndex in
            let section = sections[sectionIndex]
            Text(section.title)
              .localized(
                weight: .medium,
                size: 16,
                color: .greyScaleWhite)
              .id(Identifier.sectionHeader(at: sectionIndex).rawValue)
              .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
              ForEach(section.items.indices, id: \.self) { rowIndex in
                let log = section.items[rowIndex]

                LogRow(
                  model: log,
                  index: rowIndex,
                  onSelected: {
                    onRowSelected?(log)
                  })
              }
            }
            .padding(.bottom, 24)
            .id(Identifier.section(at: sectionIndex).rawValue)
          }

          SwiftUIGradientArcView(lineWidth: 3)
            .visibility(isPageLoading ? .visible : .gone)
            .frame(width: 24, height: 24)
        }
      }
      else {
        SwiftUIEmptyStateView(
          iconImage: Image("No Records"),
          description: Localize.string("common_no_record_temporarily"),
          keyboardAppearance: .impossible)
          .id(Identifier.emptyStateView.rawValue)
      }
    }
    else {
      Spacer()
    }
  }
}
