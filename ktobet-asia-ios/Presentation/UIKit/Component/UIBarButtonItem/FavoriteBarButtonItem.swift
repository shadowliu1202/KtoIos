import UIKit

class FavoriteBarButtonItem: KTOBarButtonItem {
    override func setupUI() {
        super.setupUI()
        button.allImage = KTOBarButtonItemStyle.favorite.image
    }
}
