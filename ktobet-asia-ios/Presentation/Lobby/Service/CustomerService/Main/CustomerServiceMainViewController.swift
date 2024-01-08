import Combine
import sharedbu
import SwiftUI
import UIKit

final class CustomerServiceMainViewController: LobbyViewController {
  @Injected private var viewModel: CustomerServiceMainViewModel
  
  private var cancellables = Set<AnyCancellable>()
  private var router = CustomerServiceMainRouter()
  private var activityIndicator = UIActivityIndicatorView(style: .large)
  
  var barButtonItems: [UIBarButtonItem] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    binding()
  }
  
  private func setupUI() {
    router.vc = self
    
    NavigationManagement.sharedInstance.addMenuToBarButtonItem(
      vc: self,
      title: Localize.string("customerservice_online"))
    
    addSubView(from: { [unowned self] in
      CustomerServiceMainView(
        viewModel: viewModel,
        onTapServiceButton: { [unowned self] hasPrechat in
          self.toServiceView(hasPrechat)
        }, onTapRow: { [unowned self] in
          didSelectRowAt(roomId: $0)
        })
    }, to: view)
    
    addIndicator()
  }
  
  private func addIndicator() {
    activityIndicator.center = self.view.center
    view.addSubview(activityIndicator)
  }

  private func toServiceView(_ hasPrechat: Bool) {
    if NetworkStateMonitor.shared.isNetworkConnected {
      if hasPrechat {
        router.toPrechat()
      }
      else {
        router.toCalling()
      }
    }
    else {
      showToast()
    }
  }
  
  private func showToast() {
    showToast(Localize.string("common_unknownhostexception"), barImg: .failed)
  }
  
  private func didSelectRowAt(roomId: String) {
    router.toHistory(roomId: roomId)
  }
  
  private func binding() {
    viewModel.$histories
      .map { $0.isEmpty }
      .sink(receiveValue: { [unowned self] in setupEditButton($0) })
      .store(in: &cancellables)
    
    viewModel.errors()
      .sink(receiveValue: { [unowned self] in handleErrors($0) })
      .store(in: &cancellables)
  }
  
  private func setupEditButton(_ isHidden: Bool) {
    if isHidden {
      self.navigationItem.rightBarButtonItems?.removeAll()
    }
    else {
      let padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
      let edit = UIBarButtonItem.kto(.text(text: Localize.string("common_edit")))
      self.bind(position: .right, barButtonItems: [padding, edit])
    }
  }
}

extension CustomerServiceMainViewController: BarButtonItemable {
  func pressedRightBarButtonItems(_: UIBarButtonItem) {
    router.toEdit()
  }
}
