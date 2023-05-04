import Foundation

protocol LogSectionModelBuilder { }

extension LogSectionModelBuilder {
  func regrouping<T, M>(
    from items: [T],
    by date: (T) -> String,
    converter: ((T) -> [M])? = nil)
    -> [LogSections<M>.Model]
    where M: LogRowModel
  {
    Dictionary(grouping: items, by: { date($0) })
      .map { dateString, groupLog -> LogSections<M>.Model in
        let today = Date().convertdateToUTC().toDateString()
        let sectionTitle = dateString == today ? Localize.string("common_today") : dateString

        var _items: [M] = []

        if let converter {
          _items = groupLog.flatMap { converter($0) }
        }
        else if let origin = groupLog as? [M] {
          _items = origin
        }

        return .init(title: sectionTitle, items: _items)
      }
      .sorted(by: { $0.title > $1.title })
  }
}
