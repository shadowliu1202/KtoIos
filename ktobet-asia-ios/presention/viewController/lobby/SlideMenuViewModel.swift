import Foundation
import SharedBu
import RxSwift
import RxCocoa

class SlideMenuViewModel {
    
    let features = Observable<[FeatureItem]>.from(optional: [
        FeatureItem(type: .deposit, name: Localize.string("common_deposit"), icon: "Deposit"),
        FeatureItem(type: .withdraw, name: Localize.string("common_withdrawal"), icon: "Withdrawl"),
        FeatureItem(type: .callService, name: Localize.string("common_customerservice"), icon: "Customer Service"),
        FeatureItem(type: .logout, name: Localize.string("common_logout"), icon: "Logout")])
    
    lazy var products = getProducts()
    
    var currentSelectedCell: ProductItemCell?
    var currentSelectedProductType: ProductType?
    
    private func getProducts() -> [ProductItem] {
        var titles = [Localize.string("common_sportsbook"),
                      Localize.string("common_casino"),
                      Localize.string("common_slot"),
                      Localize.string("common_keno"),
                      Localize.string("common_p2p"),
                      Localize.string("common_arcade")]
        
        var imgs = ["SBK", "Casino", "Slot", "Number Game", "P2P", "Arcade"]
        var type : [ProductType] = [.sbk, .casino, .slot, .numbergame, .p2p, .arcade]
        var arr = [ProductItem]()
        
        titles.enumerated()
            .forEach { index, title in
                let item = ProductItem(title: titles[index], image: imgs[index], type: type[index])
                arr.append(item)
            }
        
        return arr
    }
}

struct ProductItem {
    var title = ""
    var image = ""
    var type = ProductType.none
    var maintainTime: OffsetDateTime?
}

struct FeatureItem {
    var type: FeatureType
    var name: String
    var icon: String
}
