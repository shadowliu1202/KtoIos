import SwiftUI

struct LogHeader<Content: View>: View {
  let title: String
  let currentDateType: DateType
  var dateFilterAction: DateFilter.Action?

  let filterTitle: String
  var onPresentFilterController: (() -> Void)?

  let content: () -> Content

  init(
    title: String,
    currentDateType: DateType,
    dateFilterAction: DateFilter.Action? = nil,
    filterTitle: String,
    onPresentFilterController: (() -> Void)? = nil,
    @ViewBuilder content: @escaping (() -> Content) = { EmptyView() })
  {
    self.title = title
    self.currentDateType = currentDateType
    self.dateFilterAction = dateFilterAction
    self.filterTitle = filterTitle
    self.onPresentFilterController = onPresentFilterController
    self.content = content
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 30) {
      Text(title)
        .localized(weight: .semibold, size: 24, color: .whitePure)
        .padding(.leading, 6)

      VStack(spacing: 16) {
        VStack(spacing: 12) {
          DateFilter(
            currentType: currentDateType,
            action: dateFilterAction)

          TypeFilter(
            title: filterTitle,
            onPresentController: onPresentFilterController)
        }

        content()
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
