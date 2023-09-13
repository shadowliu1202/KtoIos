import UIKit

class CustomImagePickerController: UIImagePickerController {
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    CustomServicePresenter.shared.setFloatIconAvailable(false)
  }
    
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    CustomServicePresenter.shared.setFloatIconAvailable(true)
  }
}
