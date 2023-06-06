import UIKit

class FilterBarButtonItem: KTOBarButtonItem {
  override func setupUI() {
    super.setupUI()
    button.allImage = KTOBarButtonItemStyle.filter.image
  }
}
