import UIKit
import RxSwift
import SharedBu
import SwiftUI

class TextBarButtonItem: UIBarButtonItem {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init(title: String?) {
        super.init()
        self.title = title
        self.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "PingFangSC-Semibold", size: 16)!], for: .normal)
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.whiteFull], for: .normal)
    }
}

let registerBarBtnId = 1001
let customerServiceBarBtnId = 1002
let loginBarBtnId = 1003
let manualUpdateBtnId = 1004
let skipBarBtnId = 1005

class CustomerServiceButtonItem: TextBarButtonItem {
    weak var delegate: CustomServiceDelegate? = nil
    let serviceStatusViewModel = DI.resolve(ServiceStatusViewModel.self)!
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init(_ delegate: CustomServiceDelegate? = nil, _ disposeBag: DisposeBag) {
        super.init(title: Localize.string("customerservice_action_bar_title"))
        self.senderId(customerServiceBarBtnId)
        self.delegate = delegate
        self.delegate?.monitorChatRoomStatus(disposeBag)
        self.actionHandler({ [weak self] _ in
            guard let `self` = self, let vc = self.delegate as? UIViewController else { return }
            self.isEnabled = false
            
            self.serviceStatusViewModel.output.portalMaintenanceStatus.drive(onNext: { maintenanceStatus in
                switch maintenanceStatus {
                case is MaintenanceStatus.AllPortal:
                    Alert.show(Localize.string("common_maintenance_notify"), Localize.string("common_maintenance_contact_later"), confirm: {
                        self.isEnabled = true
                        NavigationManagement.sharedInstance.goTo(storyboard: "Maintenance", viewControllerId: "PortalMaintenanceViewController")
                    }, cancel: nil)
                case is MaintenanceStatus.Product:
                    CustomService.startCustomerService(from: vc, delegate: self.delegate)
                        .subscribe(onCompleted: { [weak self] in
                            self?.isEnabled = true
                        }, onError: { [weak self] in
                            self?.isEnabled = true
                            vc.handleErrors($0)
                        }).disposed(by: disposeBag)
                default:
                    self.isEnabled = true
                    break
                }
            }).disposed(by: disposeBag)
        })
    }
}

class RegisterButtonItem: TextBarButtonItem {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init() {
        super.init(title: Localize.string("common_register"))
        self.senderId(registerBarBtnId)
    }
}

class LoginButtonItem: TextBarButtonItem {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init() {
        super.init(title: Localize.string("common_login"))
        self.senderId(loginBarBtnId)
    }
}

class ManualUpdateButtonItem: TextBarButtonItem {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init() {
        super.init(title: Localize.string("update_title"))
        self.senderId(manualUpdateBtnId)
    }
}
