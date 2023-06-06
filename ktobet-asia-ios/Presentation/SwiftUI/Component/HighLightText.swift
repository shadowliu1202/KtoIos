import SwiftUI
import UIKit

struct HighLightText: View {
  static let Identifier = "HighLightText"

  private let wholeSentence: String

  let highlights: [(keyword: String, color: UIColor)]

  init(_ wholeSentence: String) {
    self.wholeSentence = wholeSentence
    self.highlights = []
  }

  private init(_ wholeSentence: String, highlights: [(keyword: String, color: UIColor)]) {
    self.wholeSentence = wholeSentence
    self.highlights = highlights
  }

  var body: some View {
    ZStack {
      Text(wholeSentence)

      ForEach(highlights.indices, id: \.self) { index in
        highLightText(
          keyword: highlights[index].keyword,
          color: highlights[index].color)
      }
    }
  }

  private func highLightText(keyword: String, color: UIColor) -> Text {
    let textList = wholeSentence
      .components(separatedBy: keyword)
      .map { substring in
        String(substring)
      }

    let highLightText = textList
      .reduce(Text("")) { partialResult, nextString in
        let text = nextString == textList.last
          ? Text(nextString).foregroundColor(.clear)
          : Text(nextString).foregroundColor(.clear) + Text(keyword).foregroundColor(.from(color))

        return partialResult + text
      }

    return highLightText
  }

  func highLight(_ keyword: String, with color: UIColor) -> HighLightText {
    var newHighlights = highlights
    newHighlights.append((keyword, color))

    return HighLightText(wholeSentence, highlights: newHighlights)
  }
}

struct HighLightText_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      HighLightText("和尚端湯上塔，塔滑湯灑湯燙塔。")
        .highLight("湯", with: .primaryDefault)
        .highLight("塔", with: .alert)
        .localized(weight: .semibold, size: 24, color: .purple)
    }
  }
}
