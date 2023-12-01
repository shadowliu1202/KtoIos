import sharedbu
import SwiftUI

extension CustomerServiceMainView {
  enum Identifier: String {
    case serviceButton
    case icon
    case title
  }
}

struct CustomerServiceMainView<ViewModel>: View
  where ViewModel:
  CustomerServiceMainViewModelProtocol &
  ObservableObject
{
  @StateObject private var viewModel: ViewModel

  var onTapServiceButton: ((Bool) -> Void)?
  var onTapRow: ((String) -> Void)?
  
  init(
    viewModel: ViewModel,
    onTapServiceButton: ((Bool) -> Void)?,
    onTapRow: ((String) -> Void)?)
  {
    self._viewModel = StateObject(wrappedValue: viewModel)
    self.onTapServiceButton = onTapServiceButton
    self.onTapRow = onTapRow
  }
  
  var body: some View {
    PageContainer(bottomPadding: 0, alignment: .top) {
      ServiceButton(
        isChatting: viewModel.isChatRoomExist,
        onTapButton: {
          let hasPrechat = await viewModel.hasPreChatSurvey()
          onTapServiceButton?(hasPrechat)
        })
        .disabled(viewModel.isChatRoomExist)
        
      if viewModel.histories.isEmpty {
        SwiftUIEmptyStateView(
          iconImage: Image("No Chat Records"),
          description: Localize.string("customerservice_chat_history_empty"),
          keyboardAppearance: .possible)
      }
      else {
        LimitSpacer(30)
        
        RecordList(
          viewModel: viewModel,
          histories: viewModel.histories,
          timeZone: viewModel.getTimeZone(),
          onSelectedRow: { roomId in
            onTapRow?(roomId)
          })
      }
    }
    .onViewDidLoad {
      viewModel.setup()
    }
    .onAppear {
      viewModel.refreshData()
    }
  }
}

extension CustomerServiceMainView {
  struct ServiceButton: View {
    var isChatting: Bool
    var onTapButton: (() async -> Void)?
    
    var inspection = Inspection<Self>()
    
    var body: some View {
      VStack {
        if isChatting {
          serviceButton(
            icon: "CS_connected",
            lableTextKey: "customerservice_call_connected",
            buttonStyle: .border)
        }
        else {
          serviceButton(
            icon: "CS_immediately",
            lableTextKey: "customerservice_call_immediately",
            buttonStyle: .fill)
        }
      }
      .onInspected(inspection, self)
    }
    
    func serviceButton(icon: String, lableTextKey: String, buttonStyle: some ButtonStyle) -> some View {
      AsyncButton(
        label: {
          HStack {
            Image(icon)
              .id(CustomerServiceMainView.Identifier.icon.rawValue)
            
            LimitSpacer(10)
            
            Text(Localize.string(lableTextKey))
              .id(CustomerServiceMainView.Identifier.title.rawValue)
          }
          .padding(.init(top: 12, leading: 15, bottom: 11, trailing: 12))
        },
        action: {
          await onTapButton?()
        })
        .buttonStyle(buttonStyle)
        .localized(weight: .semibold, size: 16)
        .id(CustomerServiceMainView.Identifier.serviceButton.rawValue)
    }
  }
}

extension CustomerServiceMainView {
  struct RecordList: View {
    @ObservedObject var viewModel: ViewModel
    
    var histories: [CustomerServiceDTO.ChatHistoriesHistory]
    var timeZone: Foundation.TimeZone
    var onSelectedRow: ((String) -> Void)?
    
    var body: some View {
      Divider()
        .frame(height: 1)
        .overlay(Color(UIColor.textSecondary))
      
      List(histories.indices, id: \.self) { index in
        let item = histories[index]
        CustomerServiceMainView.ItemRow(history: item, timeZone: timeZone)
          .onAppear {
            if item == histories.last {
              viewModel.getMoreHistories()
            }
          }
          .onTapGesture {
            onSelectedRow?(item.roomId)
          }
      }
      .listStyle(.plain)
    }
  }
}

extension CustomerServiceMainView {
  struct ItemRow: View {
    var history: CustomerServiceDTO.ChatHistoriesHistory
    var timeZone: Foundation.TimeZone
    
    var body: some View {
      VStack(alignment: .leading, spacing: 0) {
        VStack(alignment: .leading, spacing: 4) {
          Text(history.createDate.toLocalDateTime(timeZone).toDateTimeFormatString())
            .localized(weight: .medium, size: 14, color: .textPrimary)
          
          Text(history.title)
            .lineLimit(2)
            .localized(weight: .regular, size: 14, color: .greyScaleWhite)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 24)
        
        Divider()
          .frame(height: 1)
          .overlay(Color(UIColor.textSecondary))
      }
      .listRowInsets(EdgeInsets())
      .backgroundColor(.greyScaleDefault)
    }
  }
}

struct CustomerServiceMainView_Previews: PreviewProvider {
  class FakeViewModel:
    CustomerServiceMainViewModelProtocol,
    ObservableObject
  {
    var isChatRoomExist = true
    var histories: [CustomerServiceDTO.ChatHistoriesHistory] = []
    
    func getTimeZone() -> Foundation.TimeZone { .autoupdatingCurrent }
    func hasPreChatSurvey() async -> Bool { false }
    func getMoreHistories() { }
    func refreshData() { }
    func setup() {}
  }
  
  static var previews: some View {
    CustomerServiceMainView(
      viewModel: FakeViewModel(),
      onTapServiceButton: { _ in },
      onTapRow: { _ in })
  }
}
