import SwiftUI

extension DropDownList {
  enum Identifier: String {
    case candidateWordList
  }
  
  enum Style {
    case conversation
    case rectangle
  }
}

struct DropDownList: View {
  @State private var baseComponentHeight: CGFloat = 0
  @State private var isBaseComponentInTopSide = true
  
  @Binding private var selectedItem: String
  @Binding private var isFocus: Bool
  
  private let id: UUID
  private let items: [String]
  private let listStyle: DropDownList.Style
  
  init(
    id: UUID,
    items: [String],
    listStyle: DropDownList.Style = .conversation,
    selectedItem: Binding<String>,
    isFocus: Binding<Bool>)
  {
    self.id = id
    self.items = items
    self.listStyle = listStyle
    self._selectedItem = selectedItem
    self._isFocus = isFocus
  }

  var list: some View {
    VStack(alignment: .leading, spacing: 0) {
      Image("Triangle16x8")
        .alignmentGuide(.leading, computeValue: { $0[.leading] - 20 })
        .visibility(isBaseComponentInTopSide ? .visible : .invisible)
        .visibility(listStyle == .conversation ? .visible : .gone)

      ZStack {
        Color.from(.greyScaleToast)
          .cornerRadius(listStyle == .conversation ? 8 : 0)

        ScrollView(showsIndicators: false) {
          if items.isEmpty {
            Text(Localize.string("common_empty_data"))
              .localized(weight: .regular, size: 16, color: .textSecondary)
              .frame(height: 74)
          }
          else {
            VStack(spacing: 0) {
              ForEach(items, id: \.self) { item in
                Text(item)
                  .localized(weight: .regular, size: 16, color: .textPrimary)
                  .padding(12)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .contentShape(Rectangle())
                  .onTapGesture {
                    selectedItem = item

                    isFocus = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                  }
              }
              .id(DropDownList.Identifier.candidateWordList.rawValue)
            }
            .padding(.vertical, 12)
          }
        }
      }
      .frame(height: items.isEmpty ? 72 : 225)
      .zIndex(1)

      Image("Triangle16x8")
        .rotationEffect(.degrees(180), anchor: .center)
        .alignmentGuide(.leading, computeValue: { $0[.leading] - 20 })
        .visibility(isBaseComponentInTopSide ? .invisible : .visible)
        .visibility(listStyle == .conversation ? .visible : .gone)
    }
  }
  
  var body: some View {
    ZStack {
      GeometryReader { geometryProxy in
        Color.clear
          .onAppear {
            baseComponentHeight = geometryProxy.size.height
          }
          .onChange(of: geometryProxy.size) { size in
            withAnimation(.easeOut(duration: 0.2)) {
              baseComponentHeight = size.height
            }
          }
      }
    }
    .positionDetect(result: $isBaseComponentInTopSide)
    .overlay(
      list
        .visibility(isFocus ? .visible : .gone)
        .alignmentGuide(.top, computeValue: {
          let offset: CGFloat = listStyle == .conversation ? 2 : 0
          return $0[.top] - (baseComponentHeight + offset)
        })
        .alignmentGuide(.bottom, computeValue: {
          let offset: CGFloat = listStyle == .conversation ? 2 : 0
          return $0[.bottom] + (baseComponentHeight + offset)
        }),
      alignment: isBaseComponentInTopSide ? .top : .bottom)
    .onReceive(
      NotificationCenter.default.publisher(for: Notification.Name("TopSideDetectListShouldCollapse")),
      perform: { notification in
        if
          let userInfo = notification.userInfo,
          let senderId = userInfo["senderId"] as? UUID,
          senderId != self.id
        {
          isFocus = false
        }
      })
  }

  static func notifyTopSideDetectListShouldCollapse(id: UUID) {
    NotificationCenter.default.post(
      name: Notification.Name("TopSideDetectListShouldCollapse"),
      object: nil,
      userInfo: ["senderId": id])
  }
}

struct TopSideDetectList_Previews: PreviewProvider {
  struct Preview: View {
    @EnvironmentObject private var safeAreaMonitor: SafeAreaMonitor
    
    @State private var viewHeight = CGFloat()
    
    var body: some View {
      ScrollView {
        VStack {
          Rectangle()
            .frame(height: 100)
            .overlay(
              DropDownList(
                id: UUID(),
                items: ["1", "2", "3", "4", "5", "6", "7", "8", "9"],
                listStyle: .conversation,
                selectedItem: .constant(""),
                isFocus: .constant(true)))
            .padding(.horizontal, 30)
          
          LimitSpacer(150)
        }
        .frame(height: safeAreaMonitor.safeAreaSize.height, alignment: .center)
      }
    }
  }
  
  static var previews: some View {
    SafeAreaReader {
      Preview()
    }
  }
}
