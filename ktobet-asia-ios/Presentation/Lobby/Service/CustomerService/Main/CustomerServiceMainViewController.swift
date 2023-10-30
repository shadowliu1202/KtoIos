import Combine
import sharedbu
import SwiftUI
import UIKit

final class CustomerServiceMainViewController: LobbyViewController {
  @Injected private var viewModel: CustomerServiceMainViewModel
  @Injected private var csViewModel: CustomerServiceViewModel
  @Injected private var surveyViewModel: SurveyViewModel
  
  private var cancellables = Set<AnyCancellable>()
  
  var barButtonItems: [UIBarButtonItem] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    binding()
  }
  
  deinit {
    Logger.shared.info("\(type(of: self)) deinit")
  }
  
  private func setupUI() {
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
  }

  private func toServiceView(_ hasPrechat: Bool) {
    if NetworkStateMonitor.shared.isNetworkConnected {
      if hasPrechat {
        toPrechat()
      }
      else {
        toCalling()
      }
    }
    else {
      showToast()
    }
  }
  
  private func toPrechat() {
    CustomServicePresenter.shared.switchToPrechat(from: self, vm: surveyViewModel, csViewModel: csViewModel)
  }
  
  private func toCalling() {
    CustomServicePresenter.shared.switchToCalling(isRoot: true)
  }
  
  private func showToast() {
    showToast(Localize.string("common_unknownhostexception"), barImg: .failed)
  }
  
  private func didSelectRowAt(roomId: String) {
    let vc = UIStoryboard(name: "CustomService", bundle: nil)
      .instantiateViewController(withIdentifier: "ChatHistoryViewController") as! ChatHistoryViewController
    vc.roomId = roomId
    navigationController?.pushViewController(vc, animated: true)
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
    let vc = UIStoryboard(name: "CustomService", bundle: nil)
      .instantiateViewController(
        withIdentifier: "CustomerServiceHistoryEditViewController") as! CustomerServiceHistoryEditViewController
    navigationController?.pushViewController(vc, animated: true)
  }
}
