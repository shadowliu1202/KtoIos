import UIKit

final class CustomerServiceMainRouter {
  weak var vc: CustomerServiceMainViewController?
  
  func toCalling() {
    let to = CallingViewController(surveyAnswers: nil)
    let navi = CustomServiceNavigationController(rootViewController: to)
    navi.modalPresentationStyle = .fullScreen
    vc?.present(navi, animated: false)
  }
  
  func toHistory(roomId: String) {
    guard
      let to = UIStoryboard(name: "CustomService", bundle: nil)
        .instantiateViewController(withIdentifier: "ChatHistoryViewController") as? ChatHistoryViewController else { return }
    to.roomId = roomId
    vc?.navigationController?.pushViewController(to, animated: true)
  }
  
  func toEdit() {
    let to = ChatHistoriesEditViewController()
    vc?.navigationController?.pushViewController(to, animated: true)
  }
  
  func toOfflineMessage() {
    let to = OfflineMessageViewController()
    let skip = UIBarButtonItem.kto(.text(text: Localize.string("common_skip")))
    to.bind(position: .right, barButtonItems: skip)
    let navi = UINavigationController(rootViewController: to)
    navi.modalPresentationStyle = .fullScreen
    vc?.present(navi, animated: false)
  }
  
  func toPrechat() {
    let to = CustomServiceNavigationController(rootViewController: PrechatSurveyViewController())
    to.modalPresentationStyle = .overCurrentContext
    vc?.present(to, animated: true)
  }
}
