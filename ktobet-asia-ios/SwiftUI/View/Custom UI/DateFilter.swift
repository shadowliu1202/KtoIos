import SwiftUI

struct DateFilter: View {
  typealias Selection = (_ type: DateType) -> Void

  @State var currentType: DateType

  var onDateSelected: Selection?

  var body: some View {
    FunctionalButton(
      imageName: "iconDatePicker24",
      content: {
        Text(currentType.description)
          .localized(
            weight: .medium,
            size: 14,
            color: .gray9B9B9B)
          .lineLimit(1)
      },
      action: {
        navigateToDateSelector()
      })
  }
}

extension DateFilter {
  private func navigateToDateSelector() {
    let storyboard = UIStoryboard(name: "Date", bundle: nil)
    guard
      let controller = storyboard
        .instantiateViewController(withIdentifier: "DateConditionViewController") as? DateViewController
    else { fatalError("DateViewController init error !!") }

    controller.dateType = currentType
    controller.conditionCallback = {
      self.currentType = $0
      self.onDateSelected?($0)
    }

    NavigationManagement.sharedInstance.pushViewController(vc: controller)
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
