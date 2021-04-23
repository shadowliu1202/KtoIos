import UIKit

class SearchButtonItem: KTOBarButtonItem {
    override func setupUI() {
        super.setupUI()
        button.allImage = KTOBarButtonItemStyle.search.image
    }
}
