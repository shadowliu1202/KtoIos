import Foundation
import SharedBu
import RxSwift

class SlideMenuViewModel {
    let features = Observable<[FeatureItem]>.from(optional: [
        FeatureItem(type: .deposit, name: Localize.string("common_deposit"), icon: "Deposit"),
        FeatureItem(type: .withdraw, name: Localize.string("common_withdrawal"), icon: "Withdrawl"),
        FeatureItem(type: .callService, name: Localize.string("common_customerservice"), icon: "Customer Service"),
        FeatureItem(type: .logout, name: Localize.string("common_logout"), icon: "Logout")])
    
    let arrProducts = Observable<[ProductItem]>.from(optional: {
        var titles = [Localize.string("common_sportsbook"), Localize.string("common_casino"), Localize.string("common_slot"), Localize.string("common_keno"), Localize.string("common_p2p"), Localize.string("common_arcade")]
        var imgs = ["SBK", "Casino", "Slot", "Number Game", "P2P", "Arcade"]
        var type : [ProductType] = [.sbk, .casino, .slot, .numbergame, .p2p, .arcade]
        var arr = [ProductItem]()
        for idx in 0..<titles.count{
            let item = ProductItem(title: titles[idx], image: imgs[idx] , type: type[idx])
            arr.append(item)
        }
        return arr
    }())
    
    var currentSelectedCell: ProductItemCell?
    var currentSelectedProductType: ProductType?
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
