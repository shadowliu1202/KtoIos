import UIKit
import SharedBu


protocol ServiceStatusNavigator {
    func toSBKMaintainPage()
    func toDefaultProductMaintainPage(playerType: ProductType, maintainType: ProductType)
    func toPlayerType(playerType: ProductType)
    func toPortalMaintainPage()
}

class ServiceStatusNavigatorImpl: ServiceStatusNavigator {
    func toSBKMaintainPage() {
        NavigationManagement.sharedInstance.goTo(productType: .sbk, isMaintenance: true)
    }
    
    func toDefaultProductMaintainPage(playerType: ProductType, maintainType: ProductType) {
        NavigationManagement.sharedInstance.goTo(productType: playerType, isMaintenance: true)
        showDefaultProductMaintenAlert(playerDefaultProductType: playerType, gotoProductType: maintainType)
    }
    
    func toPlayerType(playerType: ProductType) {
        NavigationManagement.sharedInstance.goTo(productType: playerType)
    }
    
    func toPortalMaintainPage() {
        Alert.show(Localize.string("common_maintenance_notify"), Localize.string("common_maintenance_contact_later"), confirm: {
            NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
        }, cancel: nil)
    }
    
    private func showDefaultProductMaintenAlert(playerDefaultProductType: ProductType, gotoProductType: ProductType) {
        Alert.show(Localize.string("common_maintenance_notify"), Localize.string("common_default_product_maintain_content", StringMapper.sharedInstance.parseProductTypeString(productType: playerDefaultProductType)), confirm: {
            NavigationManagement.sharedInstance.goTo(productType: gotoProductType)
        }, cancel: nil)
    }
}
