import SwiftUI

@available(*, deprecated)
struct FilterSelector<Presenter>: View
  where Presenter: Selecting & ObservableObject
{
  @StateObject var presenter: Presenter

  @State var selectedItems: [Selectable]

  var haveSelectAll = false
  var selectAtLeastOne = false
  var allowMultipleSelection = false

  var onDone: (() -> Void)?

  var body: some View {
    VStack(spacing: 16) {
      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 14) {
          Text(Localize.string("common_filter"))
            .localized(
              weight: .semibold,
              size: 24,
              color: .greyScaleWhite)
            .padding(.horizontal, 30)

          ItemSelector(
            dataSource: presenter.dataSource,
            selectedItems: $selectedItems,
            haveSelectAll: haveSelectAll,
            selectAtLeastOne: selectAtLeastOne,
            allowMultipleSelection: allowMultipleSelection)
        }
      }

      PrimaryButton(
        title: Localize.string("common_done"),
        action: {
          presenter.selectedItems = selectedItems
          onDone?()
        })
        .padding(.horizontal, 30)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 30)
    .padding(.bottom, 16)
    .pageBackgroundColor(.greyScaleDefault)
  }
}

struct FilterSelector_Previews: PreviewProvider {
  class ViewModel: Selecting,
    ObservableObject
  {
    var dataSource: [Selectable] = TransactionLogViewModel.LogType.allCases
    @Published var selectedItems: [Selectable] = []
    var selectedTitle = ""
  }

  static var previews: some View {
    FilterSelector(
      presenter: ViewModel(),
      selectedItems: [],
      haveSelectAll: true)
  }
}
