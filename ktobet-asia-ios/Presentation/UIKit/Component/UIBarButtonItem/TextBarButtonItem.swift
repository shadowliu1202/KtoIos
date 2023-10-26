import RxSwift
import sharedbu
import SwiftUI
import UIKit

class TextBarButtonItem: UIBarButtonItem {
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  init(title: String?) {
    super.init()
    self.title = title
    self.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "PingFangSC-Semibold", size: 16)!], for: .normal)
    self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.greyScaleWhite], for: .normal)
  }
}

let registerBarBtnId = 1001
let customerServiceBarBtnId = 1002
let loginBarBtnId = 1003
let manualUpdateBtnId = 1004
let skipBarBtnId = 1005

class CustomerServiceButtonItem: TextBarButtonItem {
  @Injected private var customerServiceViewModel: CustomerServiceViewModel
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  init(serviceStatusViewModel: ServiceStatusViewModel, _ delegate: CustomServiceDelegate, _ disposeBag: DisposeBag) {
    super.init(title: Localize.string("customerservice_action_bar_title"))
    self.senderId(customerServiceBarBtnId)
    self.isEnabled = false
    
    customerServiceViewModel.isPlayerInChat
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak delegate] in
        delegate?.didCsIconAppear(isAppear: $0)
        
        if self.isEnabled == false {
          self.isEnabled = true
        }
      })
      .disposed(by: disposeBag)
    
    self.actionHandler({ [weak self, weak serviceStatusViewModel, weak delegate] _ in
      guard
        let self,
        let vc = delegate as? UIViewController,
        let serviceStatusViewModel
      else { return }
      
      self.isEnabled = false

      serviceStatusViewModel.output.portalMaintenanceStatus.subscribe(onNext: { maintenanceStatus in
        switch maintenanceStatus {
        case is MaintenanceStatus.AllPortal:
          Alert.shared.show(
            Localize.string("common_maintenance_notify"),
            Localize.string("common_maintenance_contact_later"),
            confirm: {
              self.isEnabled = true
              NavigationManagement.sharedInstance.goTo(
                storyboard: "Maintenance",
                viewControllerId: "PortalMaintenanceViewController")
            },
            cancel: nil)
        case is MaintenanceStatus.Product:
          CustomServicePresenter.shared.startCustomerService(from: vc)
            .subscribe(onCompleted: {
              self.isEnabled = true
            }, onError: {
              self.isEnabled = true
              vc.handleErrors($0)
            }).disposed(by: disposeBag)
        default:
          self.isEnabled = true
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
