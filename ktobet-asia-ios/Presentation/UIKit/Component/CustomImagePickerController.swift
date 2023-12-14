import AVFoundation
import UIKit

class CustomImagePickerController: UIImagePickerController {
  override func viewDidLoad() {
    super.viewDidLoad()
    checkAuthorizationStatus()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    CustomServicePresenter.shared.setFloatIconAvailable(false)
  }
    
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    CustomServicePresenter.shared.setFloatIconAvailable(true)
  }
  
  private func checkAuthorizationStatus() {
    let camStatus = AVCaptureDevice.authorizationStatus(for: .video)
    switch camStatus {
    case .denied,
         .restricted:
      if let appSettings = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(appSettings)
      }
    default:
      break
    }
  }
}
