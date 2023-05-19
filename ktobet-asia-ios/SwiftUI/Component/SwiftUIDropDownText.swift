import Combine
import SwiftUI

extension SwiftUIDropDownText {
  enum Identifier: String {
    case candidateWordList
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
      .positionDetect(result: $isInTopSide)
      .overlay(
        GeometryReader { geometryProxy in
          Color.clear
            .onAppear {
              viewHeight = geometryProxy.size.height
            }
            .onChange(of: geometryProxy.size) { size in

              withAnimation(.easeOut(duration: 0.2)) {
                viewHeight = size.height
              }
            }
        })
      .overlay(
        topSideDetectList,
        alignment: isInTopSide ? .top : .bottom)
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
      .onReceive(
        NotificationCenter.default.publisher(for: Notification.Name("collapseNotification")),
        perform: { notification in
          if
            let userInfo = notification.userInfo,
            let senderId = userInfo["senderId"] as? UUID,
            senderId != self.id
          {
            isFocus = false
          }
        })
      .zIndex(isFocus ? 1 : 0)
      .onInspected(inspection, self)
      .id(Identifier.entireView.rawValue)
  }
  
  static func notifyClearFocusState(id: UUID) {
    NotificationCenter.default.post(
      name: Notification.Name("collapseNotification"),
      object: nil,
      userInfo: ["senderId": id])
  }

  // MARK: - TopSideDetectList

  var topSideDetectList: some View {
    VStack(alignment: .leading, spacing: 0) {
      Image("Triangle16x8")
        .alignmentGuide(.leading, computeValue: { $0[.leading] - 20 })
        .visibility(isInTopSide ? .visible : .invisible)

      ZStack {
        Color.from(.greyScaleToast)
          .cornerRadius(8)

        ScrollView(showsIndicators: false) {
          if filteredItems.isEmpty {
            Text(Localize.string("common_empty_data"))
              .localized(
                weight: .regular,
                size: 16,
                color: .textSecondary)
              .frame(height: 74)
          }
          else {
            VStack(spacing: 0) {
              ForEach(filteredItems, id: \.self) { itemDescription in
                Text(itemDescription)
                  .localized(
                    weight: .regular,
                    size: 16,
                    color: .textPrimary)
                  .padding(12)
                  .frame(
                    maxWidth: .infinity,
                    alignment: .leading)
                  .contentShape(Rectangle())
                  .onTapGesture {
                    textFieldText = itemDescription

                    isFocus = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                  }
              }
              .id(SwiftUIDropDownText.Identifier.candidateWordList.rawValue)
            }
            .padding(.vertical, 12)
          }
        }
      }
      .frame(height: filteredItems.isEmpty ? 72 : 225)
      .zIndex(1)

      Image("Triangle16x8")
        .rotationEffect(
          .degrees(180),
          anchor: .center)
        .alignmentGuide(.leading, computeValue: { $0[.leading] - 20 })
        .visibility(isInTopSide ? .invisible : .visible)
    }
    .visibility(isFocus ? .visible : .gone)
    .alignmentGuide(
      .top,
      computeValue: {
        $0[.top] - (viewHeight + 2)
      })
    .alignmentGuide(
      .bottom,
      computeValue: {
        $0[.bottom] + (viewHeight + 2)
      })
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
