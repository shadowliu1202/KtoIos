import Foundation
import share_bu
import RxSwift

class SlideMenuViewModel {
    let features = Observable<[FeatureItem]>.from(optional: [FeatureItem(name: .diposit, icon: "Deposit"), FeatureItem(name: .withdraw, icon: "Withdrawl"), FeatureItem(name: .callService, icon: "Customer Service"), FeatureItem(name: .logout, icon: "Logout")])
    
    let arrProducts = Observable<[ProductItem]>.from(optional: {
        var titles = [Localize.string("common_sportsbook"), Localize.string("common_casino"), Localize.string("common_slot"), Localize.string("common_keno")]
        var imgs = ["SBK", "Casino", "Slot", "Number Game"]
        var type : [ProductType] = [.sbk, .casino, .slot, .numbergame]
        var arr = [ProductItem]()
        for idx in 0...3{
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
}

struct FeatureItem {
    var name: FeatureType
    var icon: String
}
