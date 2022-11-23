import UIKit
import SwiftUI

class CryptoVideoTutorialViewController: UIViewController,
                                         SwiftUIConverter {

    init() {
        super.init(nibName: nil, bundle: nil)
        
        modalTransitionStyle = .crossDissolve
        modalPresentationStyle = .overFullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addSubView(
            CryptoVideoTutorialView(),
            to: view
        )
    }
}
