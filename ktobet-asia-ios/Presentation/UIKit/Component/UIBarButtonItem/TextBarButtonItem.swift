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
  @Injected private var alert: AlertProtocol
  
  private let currentLocaleRelay = BehaviorRelay<SupportLocale?>(value: nil)
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  init(serviceStatusViewModel: ServiceStatusViewModel, _ delegate: CustomServiceDelegate, _ disposeBag: DisposeBag) {
    super.init(title: Localize.string("customerservice_action_bar_title"))
    self.senderId(customerServiceBarBtnId)
    self.isEnabled = false
    
    currentLocaleRelay.accept(customerServiceViewModel.getSupportLocale())
    
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

      guard self.currentLocaleRelay.value != SupportLocale.China()
      else {
        self.showServiceDownAlert()
        self.isEnabled = true
        return
      }
      
      serviceStatusViewModel.output.portalMaintenanceStatus
        .subscribe(onNext: { [weak self] maintenanceStatus in
          switch maintenanceStatus {
          case is MaintenanceStatus.AllPortal:
            self?.alert.show(
              Localize.string("common_maintenance_notify"),
              Localize.string("common_maintenance_contact_later"),
              confirm: {
                self?.isEnabled = true
                NavigationManagement.sharedInstance.goTo(
                  storyboard: "Maintenance",
                  viewControllerId: "PortalMaintenanceViewController")
              },
              cancel: nil)
          case is MaintenanceStatus.Product:
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
          default:
            self?.isEnabled = true
          }
        })
        .disposed(by: disposeBag)
    })
  }
  
  func changeLocale(_ supportLocale: SupportLocale) {
    currentLocaleRelay.accept(supportLocale)
  }
  
  private func showServiceDownAlert() {
    alert.show(
      Localize.string("common_tip_cn_down_title_warm"),
      Localize.string("common_cn_service_down"),
      confirm: nil,
      confirmText: Localize.string("common_cn_down_confirm"))
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
