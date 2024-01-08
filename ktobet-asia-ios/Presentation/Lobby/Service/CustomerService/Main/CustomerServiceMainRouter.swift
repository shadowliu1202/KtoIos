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
    let to = ChatHistoriesViewController(roomId: roomId)
    vc?.navigationController?.pushViewController(to, animated: true)
  }
  
  func toEdit() {
    let to = ChatHistoriesEditViewController()
    vc?.navigationController?.pushViewController(to, animated: true)
  }
  
  func toOfflineMessage() {
    let to = OfflineMessageViewController()
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
