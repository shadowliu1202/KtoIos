import UIKit

class TextBarButtonItem: UIBarButtonItem {
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init(title: String?) {
        super.init()
        self.title = title
        self.setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "PingFangSC-Semibold", size: 16)!], for: .normal)
        self.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.whiteFull], for: .normal)
    }
}
