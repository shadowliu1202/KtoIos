import SwiftUI

struct LogSections<T: LogRowModel>: View {
  struct Model {
    let title: String
    let items: [T]
  }

  enum Identifier {
    case sectionHeader(at: Int)
    case section(at: Int)
    case emptyReminder

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
                color: .whitePure)
              .id(Identifier.sectionHeader(at: sectionIndex).rawValue)
              .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
              ForEach(section.items.indices, id: \.self) { rowIndex in
                let log = section.items[rowIndex]

                LogRow(
                  model: log,
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
        VStack(alignment: .center, spacing: 32) {
          Image("groupCopy")

          Text(Localize.string("common_no_record_temporarily"))
            .localized(
              weight: .regular,
              size: 14,
              color: .gray9B9B9B)
        }
        .frame(
          maxHeight: .infinity)
        .id(Identifier.emptyReminder.rawValue)
      }
    }
    else {
      Spacer()
    }
  }
}
