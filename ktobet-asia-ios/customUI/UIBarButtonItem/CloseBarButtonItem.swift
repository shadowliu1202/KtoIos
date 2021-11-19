import UIKit

class CloseBarButtonItem: KTOBarButtonItem {
    override func setupUI() {
        super.setupUI()
        button.allImage = KTOBarButtonItemStyle.close.image
    }
}
