import SwiftUI
import UIKit

struct TypeFilter: View {
    typealias Selection = ([FilterItem]) -> Void

    let presenter: FilterPresentProtocol
    
    @State var currentFilters: [FilterItem] = []

    var onTypeSelected: Selection?
    var onNavigateToController: ((_ controllerCallback: Selection?) -> Void)?
    
    var selectedTitle: String {
        presenter.getSelectedTitle(currentFilters)
    }
    
    var body: some View {
        FunctionalButton(
            imageName: "icon.filter",
            content: {
                Text(selectedTitle)
                    .localized(
                        weight: .medium,
                        size: 14,
                        color: .gray9B9B9B
                    )
                    .lineLimit(1)
            },
            action: {
                onNavigateToController? {
                    currentFilters = $0
                    onTypeSelected?($0)
                }
            }
        )
        .onAppear {
            currentFilters = presenter.getDatasource()
        }
    }
}

struct TypeFilter_Previews: PreviewProvider {
    
    static var previews: some View {
        TypeFilter(
            presenter: TransactionLogPresenter()
        )
    }
}
