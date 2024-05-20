import SwiftUI

protocol Selectable {
    var identity: String { get }
    var title: String { get }
    var image: String? { get }
}

protocol Selecting: AnyObject {
    var dataSource: [Selectable] { get }
    var selectedItems: [Selectable] { get set }
    var selectedTitle: String { get }
}

extension Selecting {
    var isSelectedAll: Bool {
        selectedItems.count == dataSource.count
    }
}

@available(*, deprecated)
struct ItemSelector: View {
    let dataSource: [Selectable]

    @Binding var selectedItems: [Selectable]

    var haveSelectAll = false
    var selectAtLeastOne = false
    var allowMultipleSelection = false

    var inspection = Inspection<Self>()

    var isSelectedAll: Bool {
        selectedItems.count == dataSource.count
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                Text(Localize.string("balancelog_categoryfilter"))
                    .localized(
                        weight: .medium,
                        size: 16,
                        color: .textPrimary)

                Spacer()

                Button(
                    action: {
                        selectAllAction()
                    },
                    label: {
                        Text(
                            isSelectedAll ?
                                Localize.string("common_unselect_all") : Localize.string("common_select_all"))
                            .localized(
                                weight: .medium,
                                size: 14,
                                color: .complementaryDefault)
                    })
                    .visibility(haveSelectAll ? .visible : .gone)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 16)

            Separator()

            ForEach(dataSource.indices, id: \.self) {
                Item(
                    accessory: allowMultipleSelection ? .tick : selectedItems.count > 1 ? .tick : .circle,
                    selectable: dataSource[$0],
                    isSelected: selectedIndex(dataSource[$0]) != nil,
                    bottomLineVisible: $0 < dataSource.count - 1,
                    onSelected: {
                        handleSelection($0)
                    })
            }

            Separator()
        }
        .backgroundColor(.greyScaleDefault)
        .onInspected(inspection, self)
    }

    private func selectedIndex(_ selectable: Selectable) -> Int? {
        selectedItems.firstIndex(where: { $0.identity == selectable.identity })
    }

    private func selectAllAction() {
        if isSelectedAll {
            if selectAtLeastOne, let first = dataSource.first {
                selectedItems = [first]
            }
            else {
                selectedItems.removeAll()
            }
        }
        else {
            selectedItems = dataSource
        }
    }

    private func handleSelection(_ selectable: Selectable) {
        if let selectedIndex = selectedIndex(selectable) {
            if isSelectedAll {
                if allowMultipleSelection {
                    selectedItems.remove(at: selectedIndex)
                }
                else {
                    selectedItems.removeAll(
                        where: { $0.identity != selectable.identity })
                }
            }
            else {
                if selectAtLeastOne, selectedItems.count == 1 {
                    return
                }
                else {
                    selectedItems.remove(at: selectedIndex)
                }
            }
        }
        else {
            if !allowMultipleSelection, selectedItems.count == 1 {
                selectedItems.removeAll()
            }

            selectedItems.append(selectable)
        }
    }
}

extension ItemSelector {
    enum Accessory {
        case tick
        case circle

        var imageNames: (selected: String, unselected: String) {
            switch self {
            case .tick:
                return ("iconDoubleSelectionSelected24", "iconDoubleSelectionEmpty24")
            case .circle:
                return ("iconSingleSelectionSelected24", "iconSingleSelectionEmpty24")
            }
        }
    }

    struct Item: View {
        let accessory: Accessory
        let selectable: Selectable
        let isSelected: Bool
        let bottomLineVisible: Bool

        var onSelected: ((Selectable) -> Void)?

        var body: some View {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    if let image = selectable.image {
                        Image(image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)

                        LimitSpacer(16)
                    }

                    Text(selectable.title)
                        .localized(weight: .medium, size: 14, color: .white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    LimitSpacer(8)

                    Image(isSelected ? accessory.imageNames.selected : accessory.imageNames.unselected)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 30)

                Separator()
                    .padding(.leading, (selectable.image == nil) ? 30 : 78)
                    .visibility(bottomLineVisible ? .visible : .gone)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelected?(selectable)
            }
        }
    }
}

struct ItemSelector_Previews: PreviewProvider {
    class Presenter: ObservableObject, Selecting {
        @Published var selectedItems: [Selectable] = []

        var dataSource: [Selectable] {
            TransactionLogViewModel.LogType.allCases.filter { $0 != .all }
        }

        var selectedTitle: String { "" }
    }

    struct Preview: View {
        @StateObject var presenter = Presenter()
        @State var selectedItems: [Selectable]

        var body: some View {
            VStack {
                Text("\(presenter.selectedItems.map { $0.title }.joined(separator: " /"))")
                    .localized(weight: .regular, size: 20, color: .greyScaleWhite)

                Spacer()

                ItemSelector(
                    dataSource: TransactionLogViewModel.LogType.allCases.filter { $0 != .all },
                    selectedItems: $selectedItems,
                    haveSelectAll: true,
                    selectAtLeastOne: true,
                    allowMultipleSelection: false)
            }
            .pageBackgroundColor(.greyScaleDefault)
            .frame(maxHeight: .infinity)
        }
    }

    static var previews: some View {
        Preview(selectedItems: .init())
    }
}
