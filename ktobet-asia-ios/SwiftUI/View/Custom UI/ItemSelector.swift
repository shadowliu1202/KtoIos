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
    
    func selectedIndex(_ selectable: Selectable) -> Int? {
        selectedItems.firstIndex(where: { $0.identity == selectable.identity })
    }
}

struct ItemSelector<Presenter>: View
    where Presenter: Selecting & ObservableObject
{
    @StateObject var presenter: Presenter
    
    let accessory: Accessory
    
    var haveSelectAll: Bool = false
    var selectAtLeastOne: Bool = false
    var allowMultipleSelection: Bool = false
 
    var inspection = Inspection<Self>()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom) {
                Text(Localize.string("balancelog_categoryfilter"))
                    .localized(
                        weight: .medium,
                        size: 16,
                        color: .gray9B9B9B
                    )
                
                Spacer()
                
                Button(
                    action: {
                        selectAllAction()
                    },
                    label: {
                        Text(
                            presenter.isSelectedAll ?
                            Localize.string("common_unselect_all") : Localize.string("common_select_all")
                        )
                        .localized(
                            weight: .medium,
                            size: 14,
                            color: .yellowFFD500
                        )
                    }
                )
                .visibility(haveSelectAll ? .visible : .gone)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 16)
            
            Separator(color: .gray3C3E40)
            
            ForEach(presenter.dataSource.indices, id: \.self) {
                Item(
                    accessory: accessory,
                    selectable: presenter.dataSource[$0],
                    bottomLineVisible: $0 < presenter.dataSource.count - 1,
                    onSelected: {
                        handleSelection($0)
                    }
                )
            }
            
            Separator(color: .gray3C3E40)
        }
        .environmentObject(presenter)
        .backgroundColor(.gray131313)
        .onInspected(inspection, self)
    }
    
    private func selectAllAction() {
        if presenter.isSelectedAll {
            presenter.selectedItems.removeAll()
        }
        else {
            presenter.selectedItems = presenter.dataSource
        }
    }
    
    private func handleSelection(_ selectable: Selectable) {
        
        if let selectedIndex = presenter.selectedIndex(selectable) {
            if presenter.isSelectedAll {
                presenter.selectedItems
                    .removeAll(where: { $0.identity != selectable.identity })
            }
            else {
                if selectAtLeastOne, presenter.selectedItems.count == 1 {
                    return
                }
                else {
                    presenter.selectedItems.remove(at: selectedIndex)
                }
            }
        }
        else {
            if !allowMultipleSelection, presenter.selectedItems.count == 1 {
                presenter.selectedItems.removeAll()
            }
            
            presenter.selectedItems.append(selectable)
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
        @EnvironmentObject var presenter: Presenter
        
        let accessory: Accessory
        let selectable: Selectable
        
        let bottomLineVisible: Bool
        
        var onSelected: ((Selectable) -> Void)?
        
        var accessoryImage: String {
            presenter.selectedIndex(selectable) != nil ?
            accessory.imageNames.selected : accessory.imageNames.unselected
        }
        
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
                    
                    Image(accessoryImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 30)
                
                Separator(color: .gray3C3E40)
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
        
        var body: some View {
            VStack {
                Text("\(presenter.selectedItems.map { $0.title }.joined(separator: " /"))")
                    .localized(weight: .regular, size: 20, color: .whitePure)
                
                Spacer()
                
                ItemSelector(
                    presenter: presenter,
                    accessory: .circle,
                    haveSelectAll: true,
                    selectAtLeastOne: true,
                    allowMultipleSelection: true
                )
            }
            .pageBackgroundColor(.gray131313)
            .frame(maxHeight: .infinity)
        }
    }

    static var previews: some View {
        Preview()
    }
}
