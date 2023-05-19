import SwiftUI

@available(*, deprecated)
struct DateFilter: View {
  struct Action {
    typealias Selection = (DateType) -> Void

    var onDateSelected: Selection?
    var onPresentController: ((Selection?) -> Void)?
  }

  let currentType: DateType

  var action: Action?

  var body: some View {
    FunctionalButton(
      imageName: "iconDatePicker24",
      content: {
        Text(currentType.description)
          .localized(
            weight: .medium,
            size: 14,
            color: .textPrimary)
          .lineLimit(1)
      },
      action: {
        let onSelected = action?.onDateSelected
        action?.onPresentController?(onSelected)
      })
  }
}

extension DateType {
  fileprivate var description: String {
    switch self {
    case .week:
      return Localize.string("common_last7day")
    case .day(let date):
      return date.toMonthDayString()
    case .month(let from, _):
      return from.toYearMonthString()
    }
  }
}

struct DateFilter_Previews: PreviewProvider {
  static var previews: some View {
    DateFilter(currentType: .week())
  }
}
