import Combine
import SwiftUI

extension SwiftUIDropDownText {
  enum Identifier: String {
    case entireView
  }
}

extension SwiftUIDropDownText {
  enum FeatureType: Equatable {
    case inputAssisted
    case inputValidated
    case select

    static func == (lhs: SwiftUIDropDownText.FeatureType, rhs: SwiftUIDropDownText.FeatureType) -> Bool {
      switch (lhs, rhs) {
      case (.inputAssisted, .inputAssisted):
        return true
      case (.inputValidated, .inputValidated):
        return true
      case (.select, .select):
        return true
      default:
        return false
      }
    }
  }
}

struct SwiftUIDropDownText: View {
  @State private var isInTopSide = true
  @State private var viewHeight: CGFloat = 0

  @State private var isFocus = false

  @State private var filteredItems: [String] = []

  @Binding var textFieldText: String

  private let id = UUID()

  private let placeHolder: String
  private let items: [String]

  private let featureType: FeatureType
  private let dropDownArrowVisible: Bool
  private let onInputTextTap: (() -> Void)?

  private let errorText: String

  let inspection = Inspection<Self>()

  init(
    placeHolder: String,
    textFieldText: Binding<String>,
    errorText: String = "",
    items: [String],
    featureType: FeatureType,
    dropDownArrowVisible: Bool = true,
    onInputTextTap: (() -> Void)? = nil)
  {
    self.placeHolder = placeHolder
    self._textFieldText = textFieldText
    self.errorText = errorText
    self.items = items
    self.featureType = featureType
    self.dropDownArrowVisible = dropDownArrowVisible
    self.onInputTextTap = onInputTextTap
  }

  var body: some View {
    SwiftUIInputText(
      id: id,
      placeHolder: placeHolder,
      textFieldText: $textFieldText,
      errorText: errorText,
      featureType: dropDownArrowVisible ? .dropDownArrow : .nil,
      textFieldType: GeneralType(regex: .all),
      disableInput: featureType == .select ? true : false,
      onInputTextTap: onInputTextTap,
      isFocus: $isFocus)
      .overlay(
        DropDownList(
          id: id,
          items: filteredItems,
          selectedItem: $textFieldText,
          isFocus: $isFocus))
      .onAppear {
        filteredItems = items
      }
      .onChange(of: items) { newItems in
        filteredItems = newItems
      }
      .onChange(of: textFieldText) { keyword in
        guard
          featureType == .inputAssisted ||
          featureType == .inputValidated
        else { return }

        if keyword.isEmpty {
          filteredItems = items
        }
        else {
          filteredItems = items.filter { itemDescription in
            itemDescription.contains(keyword)
          }
        }
      }
      .onChange(of: isFocus) { newValue in
        guard
          featureType == .inputValidated,
          newValue == false
        else { return }

        if items.firstIndex(of: textFieldText) == nil {
          textFieldText = ""
        }
      }
      .zIndex(isFocus ? 1 : 0)
      .onInspected(inspection, self)
      .id(Identifier.entireView.rawValue)
  }
}

struct SwiftUIDropDownText_Previews: PreviewProvider {
  struct Preview: View {
    @EnvironmentObject private var safeAreaMonitor: SafeAreaMonitor

    @State private var textFieldText = ""
    @State private var selectedItemIndex: Int? = nil

    let fakeDatas = ["中国银行", "中国工商银行", "中国农民银行", "中国建设银行", "交通银行", "中國信託", "玉山銀行"]

    var body: some View {
      ScrollView {
        VStack {
          SwiftUIDropDownText(
            placeHolder: "银行所在省份",
            textFieldText: $textFieldText,
            items: fakeDatas,
            featureType: .inputAssisted,
            dropDownArrowVisible: false)
            .padding(.horizontal, 30)

          LimitSpacer(150)
        }
        .frame(
          height: safeAreaMonitor.safeAreaSize.height,
          alignment: .center)
        .pageBackgroundColor(.greyScaleDefault)
      }
    }
  }

  static var previews: some View {
    SafeAreaReader {
      Preview()
    }
  }
}
