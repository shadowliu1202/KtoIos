import UIKit

class CustomImageBarButtonItem: KTOBarButtonItem {
    private var imageName = ""
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    init(imgName: String) {
        self.imageName = imgName
        super.init()
    }

    override func setupUI() {
        super.setupUI()
        button.allImage = KTOBarButtonItemStyle.customIamge(named: imageName).image
    }
}
