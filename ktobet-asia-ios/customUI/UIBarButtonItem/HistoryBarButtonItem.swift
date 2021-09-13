import UIKit

class HistoryBarButtonItem: KTOBarButtonItem {
    override func setupUI() {
        super.setupUI()
        button.allImage = KTOBarButtonItemStyle.history.image
    }
}
