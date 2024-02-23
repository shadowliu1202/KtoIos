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
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  init() {
    super.init(title: Localize.string("customerservice_action_bar_title"))
    self.senderId(customerServiceBarBtnId)
  }
  
  static func create(
    by supportLocale: SupportLocale,
    customerServiceViewModel: CustomerServiceViewModel,
    serviceStatusViewModel: ServiceStatusViewModel,
    alert: AlertProtocol,
    _ delegate: CustomServiceDelegate,
    _ disposeBag: DisposeBag)
    -> CustomerServiceButtonItem
  {
    switch onEnum(of: supportLocale) {
    case .china:
      return ServiceDownCustomerServiceButton(
        customerServiceViewModel: customerServiceViewModel,
        alert: alert,
        delegate,
        disposeBag)
      
    case .vietnam:
      return ActiveCustomerServiceButton(
        customerServiceViewModel: customerServiceViewModel,
        serviceStatusViewModel: serviceStatusViewModel,
        alert: alert,
        delegate,
        disposeBag)
    }
  }
}

class ActiveCustomerServiceButton: CustomerServiceButtonItem {
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override private init() {
    super.init()
  }
  
  init(
    customerServiceViewModel: CustomerServiceViewModel,
    serviceStatusViewModel: ServiceStatusViewModel,
    alert: AlertProtocol,
    _ delegate: CustomServiceDelegate,
    _ disposeBag: DisposeBag)
  {
    super.init()
    self.isEnabled = false
    
    customerServiceViewModel.isPlayerInChat
      .observe(on: MainScheduler.asyncInstance)
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
      
      serviceStatusViewModel.output.portalMaintenanceStatus
        .subscribe(onNext: { [weak self] maintenanceStatus in
          switch onEnum(of: maintenanceStatus) {
          case .allPortal:
            alert.show(
              Localize.string("common_maintenance_notify"),
              Localize.string("common_maintenance_contact_later"),
              confirm: {
                self?.isEnabled = true
                NavigationManagement.sharedInstance.goTo(
                  storyboard: "Maintenance",
                  viewControllerId: "PortalMaintenanceViewController")
              },
              cancel: nil)
          case .product:
            CustomServicePresenter.shared.startCustomerService(from: vc)
              .subscribe(
                onCompleted: {
                  self?.isEnabled = true
                },
                onError: {
                  self?.isEnabled = true
                  vc.handleErrors($0)
                })
              .disposed(by: disposeBag)
          }
        })
        .disposed(by: disposeBag)
    })
  }
}

class ServiceDownCustomerServiceButton: CustomerServiceButtonItem {
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override private init() {
    super.init()
  }
  
  init(
    customerServiceViewModel: CustomerServiceViewModel,
    alert: AlertProtocol,
    _ delegate: CustomServiceDelegate,
    _ disposeBag: DisposeBag)
  {
    super.init()
    
    customerServiceViewModel.isPlayerInChat
      .observe(on: MainScheduler.asyncInstance)
      .subscribe(onNext: { [weak delegate] in
        delegate?.didCsIconAppear(isAppear: $0)
      })
      .disposed(by: disposeBag)
    
    self.actionHandler({ _ in
      alert.show(
        Localize.string("common_tip_cn_down_title_warm"),
        Localize.string("common_cn_service_down"),
        confirm: nil,
        confirmText: Localize.string("common_cn_down_confirm"))
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
