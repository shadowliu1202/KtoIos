import Foundation
import UIKit
import share_bu

class WithdrawalPresenter: FilterPresentProtocol {
    private var conditions = [FilterItemFactor.create(.static),
                              FilterItemFactor.create(.interactive(status: .approved)),
                              FilterItemFactor.create(.interactive(status: .reject)),
                              FilterItemFactor.create(.interactive(status: .pending)),
                              FilterItemFactor.create(.interactive(status: .floating)),
                              FilterItemFactor.create(.interactive(status: .cancel))]
    
    func getTitle() -> String {
        return Localize.string("common_filter")
    }
    func setConditions(_ items: [FilterItem]) {
        conditions = items
    }
    func getDatasource() -> [FilterItem] {
        return conditions
    }
}
