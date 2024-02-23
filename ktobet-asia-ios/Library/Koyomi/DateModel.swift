import UIKit

public enum MonthType {
  case previous
  case current
  case next
  case someMonth(Int)
}

final class DateModel: NSObject {
  // Type properties
  static let dayCountPerRow = 7
  static let maxCellCount = 42

  // Week text
  var weeks = ("SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT")

  enum WeekType: String {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    init?(_ indexPath: IndexPath) {
      let firstWeekday = Calendar.current.firstWeekday
      switch indexPath.row % 7 {
      case (8 - firstWeekday) % 7: self = .sunday
      case (9 - firstWeekday) % 7: self = .monday
      case (10 - firstWeekday) % 7: self = .tuesday
      case (11 - firstWeekday) % 7: self = .wednesday
      case (12 - firstWeekday) % 7: self = .thursday
      case (13 - firstWeekday) % 7: self = .friday
      case (14 - firstWeekday) % 7: self = .saturday
      default: return nil
      }
    }
  }

  enum SelectionMode { case single, multiple, sequence, none }
  var selectionMode: SelectionMode = .single

  struct SequenceDates { var start, end: Date? }
  lazy var sequenceDates: SequenceDates = .init(start: nil, end: nil)

  // Fileprivate properties
  var currentDates: [Date] = []
  fileprivate var selectedDates: [Date: Bool] = [:]
  fileprivate var highlightedDates: [Date] = []
  fileprivate var currentDate: Date = .init()

  // MARK: - Initialization

  override init() {
    super.init()
    setup()
  }

  // MARK: - Internal Methods -

  func cellCount(in month: MonthType) -> Int {
    if let weeksRange = calendar.range(of: .weekOfMonth, in: .month, for: atBeginning(of: month)) {
      let count = weeksRange.upperBound - weeksRange.lowerBound
      return count * DateModel.dayCountPerRow
    }
    return 0
  }

  func indexAtBeginning(in month: MonthType) -> Int? {
    if let index = calendar.ordinality(of: .day, in: .weekOfMonth, for: atBeginning(of: month)) {
      return index - 1
    }
    return nil
  }

  func indexAtEnd(in month: MonthType) -> Int? {
    if
      let rangeDays = calendar.range(of: .day, in: .month, for: atBeginning(of: month)),
      let beginning = indexAtBeginning(in: month)
    {
      let count = rangeDays.upperBound - rangeDays.lowerBound
      return count + beginning - 1
    }
    return nil
  }

  func dayString(at indexPath: IndexPath, isHiddenOtherMonth isHidden: Bool) -> String {
    if isHidden, isOtherMonth(at: indexPath) {
      return ""
    }
    let formatter: DateFormatter = .init()
    formatter.dateFormat = "d"
    return formatter.string(from: currentDates[indexPath.row])
  }

  func isOtherMonth(at indexPath: IndexPath) -> Bool {
    if
      let beginning = indexAtBeginning(in: .current), let end = indexAtEnd(in: .current),
      indexPath.row < beginning || indexPath.row > end
    {
      return true
    }
    return false
  }

  func display(in month: MonthType) {
    currentDates = []
    switch month {
    case .current:
      currentDate = Date()
    case .next,
         .previous,
         .someMonth:
      currentDate = date(of: month)
    }

    setup()
  }

  func dateString(in month: MonthType, withFormat format: String) -> String {
    let formatter: DateFormatter = .init()
    formatter.dateFormat = format
    let str = formatter.string(from: date(of: month))
    return str.replacingOccurrences(of: "/", with: " ")
  }

  func date(at indexPath: IndexPath) -> Date {
    currentDates[indexPath.row]
  }

  func willSelectDate(at indexPath: IndexPath) -> Date? {
    let date = currentDates[indexPath.row]
    return selectedDates[date] == true ? nil : date
  }

  // Select date in programmatically
  func select(from fromDate: Date, to toDate: Date?) {
    if let toDate = toDate?.convertdateToUTC() {
      set(true, withFrom: fromDate.convertdateToUTC(), to: toDate)
    }
    else {
      selectedDates[fromDate.convertdateToUTC()] = true
    }
  }

  // Unselect date in programmatically
  func unselect(from fromDate: Date, to toDate: Date?) {
    if let toDate = toDate?.formated() {
      set(false, withFrom: fromDate, to: toDate)
    }
    else if let fromDate = fromDate.formated() {
      selectedDates[fromDate] = false
    }
  }

  func unselectAll() {
    selectedDates.keys(of: true).forEach { selectedDates[$0] = false }
  }

  func select(with indexPath: IndexPath) {
    let selectedDate = date(at: indexPath)

    switch selectionMode {
    case .single:
      selectedDates.forEach { [weak self] date, isSelected in
        guard let me = self else { return }
        if selectedDate == date {
          me.selectedDates[date] = me.selectedDates[date] == true ? false : true
        }
        else if isSelected {
          me.selectedDates[date] = false
        }
      }

    case .multiple:
      selectedDates[date(at: indexPath)] = selectedDates[date(at: indexPath)] == true ? false : true

    case .sequence:

      // user has selected nothing
      if sequenceDates.start == nil, sequenceDates.end == nil {
        sequenceDates.start = selectedDate
        selectedDates[selectedDate] = true

        // user has selected sequence date
      }
      else if let _ = sequenceDates.start, let _ = sequenceDates.end {
        sequenceDates.start = selectedDate
        sequenceDates.end = nil
        selectedDates.forEach { selectedDates[$0.0] = selectedDate == $0.0 ? true : false }

        // user select selected date
      }
      else if let start = sequenceDates.start, sequenceDates.end == nil, start == selectedDate {
        sequenceDates.start = nil
        selectedDates[selectedDate] = false

        // user has selected a date
      }
      else if let start = sequenceDates.start, sequenceDates.end == nil, start != selectedDate {
        let isSelectedBeforeDay = selectedDate < start

        let result: ComparisonResult
        let componentDay: Int

        if isSelectedBeforeDay {
          result = .orderedAscending
          componentDay = -1
        }
        else {
          result = .orderedDescending
          componentDay = 1
        }

        var date = start
        var components: DateComponents = .init()
        while selectedDate.compare(date) == result {
          components.day = componentDay

          guard let nextDay = calendar.date(byAdding: components, to: date) else {
            break
          }
          selectedDates[nextDay] = true
          date = nextDay
        }

        sequenceDates.start = isSelectedBeforeDay ? selectedDate : start
        sequenceDates.end = isSelectedBeforeDay ? start : selectedDate
      }
    case .none:
      break
    }
  }

  // Use only when selectionMode is sequence
  func selectedPeriodLength(with indexPath: IndexPath) -> Int {
    let selectedDate = date(at: indexPath)

    if
      let start = sequenceDates.start, let period = start.daysSince(selectedDate), sequenceDates.end == nil,
      start != selectedDate
    {
      return abs(period) + 1
    }
    else if let start = sequenceDates.start, sequenceDates.end == nil, start == selectedDate {
      return 0
    }
    else {
      return 1
    }
  }

  // Use only when selectionMode is sequence
  func willSelectDates(with indexPath: IndexPath) -> (from: Date?, to: Date?) {
    let willSelectedDate = date(at: indexPath)

    if sequenceDates.start == nil, sequenceDates.end == nil {
      return (willSelectedDate, nil)
    }
    else if let _ = sequenceDates.start, let _ = sequenceDates.end {
      return (willSelectedDate, nil)
    }
    else if let start = sequenceDates.start, sequenceDates.end == nil, start == willSelectedDate {
      return (nil, nil)
    }
    else if let start = sequenceDates.start, sequenceDates.end == nil, start != willSelectedDate {
      return willSelectedDate < start ? (willSelectedDate, sequenceDates.start) : (sequenceDates.start, willSelectedDate)
    }
    else {
      return (nil, nil)
    }
  }

  func isSelect(with indexPath: IndexPath) -> Bool {
    let date = currentDates[indexPath.row]
    return selectedDates[date] ?? false
  }

  func isHighlighted(with indexPath: IndexPath) -> Bool {
    let date = currentDates[indexPath.row]
    return highlightedDates.contains(date)
  }

  func setHighlightedDates(from: Date, to: Date?) {
    guard let fromDate = from.formated() else { return }

    if !highlightedDates.contains(fromDate) {
      highlightedDates.append(fromDate)
    }

    if let toDate = to?.formated() {
      let isSelectedBeforeDay = toDate < from

      let result: ComparisonResult
      let componentDay: Int

      if isSelectedBeforeDay {
        result = .orderedAscending
        componentDay = -1
      }
      else {
        result = .orderedDescending
        componentDay = 1
      }

      var date = fromDate
      var components: DateComponents = .init()

      while toDate.compare(date) == result {
        components.day = componentDay

        guard let nextDay = calendar.date(byAdding: components, to: date) else {
          break
        }

        if !highlightedDates.contains(nextDay) {
          highlightedDates.append(nextDay)
        }
        date = nextDay
      }
    }
  }

  func week(at index: Int) -> String {
    switch index {
    case 0: return weeks.0
    case 1: return weeks.1
    case 2: return weeks.2
    case 3: return weeks.3
    case 4: return weeks.4
    case 5: return weeks.5
    case 6: return weeks.6
    default: return ""
    }
  }

  func getSelectedDates() -> [Date] {
    selectedDates.keys(of: true).sorted(by: >)
  }
}

// MARK: - Private Methods -

extension DateModel {
  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    let timezone = Foundation.TimeZone(secondsFromGMT: 0)!
    calendar.timeZone = timezone
    return calendar
  }

  private func setup() {
    selectedDates = [:]

    guard let indexAtBeginning = indexAtBeginning(in: .current) else { return }

    var components: DateComponents = .init()
    currentDates = (0..<DateModel.maxCellCount).compactMap { index in
      components.day = index - indexAtBeginning
      return calendar.date(byAdding: components, to: atBeginning(of: .current))
    }
    .map { (date: Date) in
      selectedDates[date] = false
      return date
    }

    let selectedDateKeys = selectedDates.keys(of: true)
    selectedDateKeys.forEach { selectedDates[$0] = true }
  }

  private func set(_ isSelected: Bool, withFrom fromDate: Date, to toDate: Date) {
    currentDates
      .filter { fromDate <= $0 && toDate >= $0 }
      .forEach { selectedDates[$0] = isSelected }
  }

  private func atBeginning(of month: MonthType) -> Date {
    var components = calendar.dateComponents([.year, .month, .day], from: date(of: month))
    components.day = 1
    return calendar.date(from: components) ?? Date()
  }

  private func date(of month: MonthType) -> Date {
    var components = DateComponents()
    components.month = {
      switch month {
      case .previous: return -1
      case .current: return 0
      case .next: return 1
      case .someMonth(let month):
        return month
      }
    }()
    return calendar.date(byAdding: components, to: currentDate) ?? Date()
  }
}
