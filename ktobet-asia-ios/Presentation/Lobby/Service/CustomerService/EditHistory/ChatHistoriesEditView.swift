import sharedbu
import SwiftUI

extension ChatHistoriesEditView {
  enum TestTag: String {
    case deleteButton
    case selectedButton
    case selectedcText
    case list
    case item
  }
}

struct ChatHistoriesEditView<ViewModel>: View
  where ViewModel:
  ChatHistoriesEditViewModelProtocol &
  ObservableObject
{
  @StateObject var viewModel: ViewModel
  
  var onSelectedRow: ((CustomerServiceDTO.ChatHistoriesHistory) -> Void)?
  var onTapDelete: (() -> Void)?
  
  var inspection = Inspection<Self>()
  
  init(
    viewModel: ViewModel,
    onSelectedRow: ((CustomerServiceDTO.ChatHistoriesHistory) -> Void)?,
    onTapDelete: (() -> Void)?)
  {
    self._viewModel = StateObject(wrappedValue: viewModel)
    self.onSelectedRow = onSelectedRow
    self.onTapDelete = onTapDelete
  }
  
  var body: some View {
    PageContainer(bottomPadding: 0, alignment: .top) {
      Header()
      
      SelectedButton()
        .id(ChatHistoriesEditView.TestTag.selectedButton.rawValue)
      
      RecordList()
        .id(ChatHistoriesEditView.TestTag.list.rawValue)
      
      DeleteButton(onTapDelete: {
        onTapDelete?()
        })
        .id(ChatHistoriesEditView.TestTag.deleteButton.rawValue)
    }
    .environmentObject(viewModel)
    .onInspected(inspection, self)
  }
}

extension ChatHistoriesEditView {
  struct Header: View {
    var body: some View {
      Text(Localize.string("customerservice_history_edit_title"))
        .localized(weight: .semibold, size: 24, color: .greyScaleWhite)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 0, leading: 30, bottom: 30, trailing: 30))
    }
  }
}

extension ChatHistoriesEditView {
  struct SelectedButton: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
      Button(action: {
        viewModel.toggleSelectAll()
      }, label: {
        Text(viewModel.selectedHistories.selectedButtonText)
          .localized(weight: .medium, size: 14, color: .complementaryDefault)
          .id(ChatHistoriesEditView.TestTag.selectedcText.rawValue)
      })
      .frame(maxWidth: .infinity, alignment: .trailing)
      .padding(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
    }
  }
}

extension ChatHistoriesEditView {
  struct RecordList: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var body: some View {
      Separator(color: .textSecondary)
      
      ScrollView {
        ForEach(viewModel.histories) { item in
          ChatHistoriesEditView.ItemRow(history: item)
            .onAppear {
              if item == viewModel.histories.last {
                viewModel.getMoreHistories()
              }
            }
            .onTapGesture {
              viewModel.updateSelection(item)
            }
        }
        .id(ChatHistoriesEditView.TestTag.item.rawValue)
        
        Separator(color: .greyScaleDefault, lineWidth: 40)
      }
    }
  }
}

extension ChatHistoriesEditView {
  struct ItemRow: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var history: CustomerServiceDTO.ChatHistoriesHistory
    
    var body: some View {
      VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 16) {
          VStack(alignment: .leading, spacing: 4) {
            Text(history.createDate.toLocalDateTime(viewModel.getTimeZone()).toDateTimeFormatString())
              .localized(weight: .medium, size: 14, color: .textPrimary)
            
            Text(history.title)
              .lineLimit(2)
              .localized(weight: .regular, size: 14, color: .greyScaleWhite)
          }
          .padding(.vertical, 24)
          .frame(maxWidth: .infinity, alignment: .leading)
          
          Image(viewModel.selectedHistories.isSelect(history) ? "iconDoubleSelectionSelected24" : "iconDoubleSelectionEmpty24")
            .frame(width: 24, height: 24)
        }
        .padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 20))
        
        Separator()
      }
      .backgroundColor(.greyScaleDefault)
    }
  }
}

extension ChatHistoriesEditView {
  struct DeleteButton: View {
    @EnvironmentObject var viewModel: ViewModel
    
    var onTapDelete: (() -> Void)?
    
    var body: some View {
      PrimaryButton(
        title: viewModel.selectedHistories.deleteButtonText,
        action: {
          await viewModel.deleteHistories()
          onTapDelete?()
        })
        .disabled(viewModel.selectedHistories.deleteCount == 0)
        .padding(.horizontal, 30)
        .padding(.vertical, 16)
        .id(ChatHistoriesEditView.TestTag.deleteButton.rawValue)
        .backgroundColor(.greyScaleDefault, alpha: 0.8)
    }
  }
}

struct ChatHistoriesEditView_Previews: PreviewProvider {
  class FakeViewModel: ChatHistoriesEditViewModelProtocol, ObservableObject {
    var selectedHistories: SelectedHistories = .init(mode: .include, selectedItems: [])
    var totalHistories: Int?
    
    var histories: [CustomerServiceDTO.ChatHistoriesHistory] = [
      .init(createDate: ClockSystem().now(), title: "test1", roomId: ""),
      .init(createDate: ClockSystem().now(), title: "test2", roomId: ""),
      .init(createDate: ClockSystem().now(), title: "test3", roomId: ""),
      .init(createDate: ClockSystem().now(), title: "test4", roomId: ""),
      .init(createDate: ClockSystem().now(), title: "test5", roomId: "")
    ]
    
    func getTimeZone() -> Foundation.TimeZone {
      .autoupdatingCurrent
    }
    
    func toggleSelectAll() { }
    
    func getDeleteCount() -> Int {
      0
    }
    
    func getMoreHistories() { }
    
    func updateSelection(_: CustomerServiceDTO.ChatHistoriesHistory) { }
    
    func deleteHistories() async { }
  }
  
  static var previews: some View {
    ChatHistoriesEditView(
      viewModel: FakeViewModel(),
      onSelectedRow: { _ in },
      onTapDelete: { })
  }
}
