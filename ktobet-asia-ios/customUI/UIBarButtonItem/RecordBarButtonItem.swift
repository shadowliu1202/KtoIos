import UIKit

class RecordBarButtonItem: KTOBarButtonItem {
    override func setupUI() {
        super.setupUI()
        button.allImage = KTOBarButtonItemStyle.record.image
    }
}
