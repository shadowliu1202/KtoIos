import UIKit
import SharedBu


protocol ServiceStatusNavigator {
    func toPortalMaintainPage()
    func toLandingPage()
    func toSBKMaintainPage()
    func toDefaultProductMaintainPage(playerType: ProductType, maintainType: ProductType)
    func toPlayerProductPage(productType: ProductType)
    func toSetDefaultProduct()
}

class ServiceStatusNavigatorImpl: ServiceStatusNavigator {
    func toPortalMaintainPage() {
        Alert.shared.show(Localize.string("common_maintenance_notify"), Localize.string("common_maintenance_contact_later"), confirm: {
            NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
        }, cancel: nil)
    }
    
    func toLandingPage() {
        NavigationManagement.sharedInstance.goTo(storyboard: "Login", viewControllerId: "LandingNavigation")
    }

    func toSBKMaintainPage() {
        NavigationManagement.sharedInstance.goTo(productType: .sbk, isMaintenance: true)
    }
    
    func toDefaultProductMaintainPage(playerType: ProductType, maintainType: ProductType) {
        NavigationManagement.sharedInstance.goTo(productType: playerType, isMaintenance: true)
        showDefaultProductMaintenAlert(playerDefaultProductType: playerType, gotoProductType: maintainType)
    }
    
    func toPlayerProductPage(productType: ProductType) {
        NavigationManagement.sharedInstance.goTo(productType: productType)
    }
    
    func toSetDefaultProduct() {
        NavigationManagement.sharedInstance.goToSetDefaultProduct()
    }
    
    private func showDefaultProductMaintenAlert(playerDefaultProductType: ProductType, gotoProductType: ProductType) {
        Alert.shared.show(Localize.string("common_maintenance_notify"), Localize.string("common_default_product_maintain_content", StringMapper.parseProductTypeString(productType: playerDefaultProductType)), confirm: {
            NavigationManagement.sharedInstance.goTo(productType: gotoProductType)
        }, cancel: nil)
    }
}
