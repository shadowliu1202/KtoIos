import sharedbu
import SwiftUI
import UIKit

class TermsOfServiceViewController: CommonViewController {
    @Injected private var locale: SupportLocale
    let barItemType: BarItemType
    let presenter: any Terms

    static func instantiate(_ presenter: any Terms, _ barItemType: BarItemType = .back) -> TermsOfServiceViewController {
        UIStoryboard(name: "Signup", bundle: nil)
            .instantiateViewController(
                identifier: "TermsOfServiceViewController",
                creator: { TermsOfServiceViewController(coder: $0, presenter: presenter, barItemType) }
            )
    }

    init?(coder: NSCoder, presenter: any Terms, _ barItemType: BarItemType) {
        self.presenter = presenter
        self.barItemType = barItemType
        super.init(coder: coder)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: barItemType)
    }
    
    @IBSegueAction func segueToHostingController(_ coder: NSCoder) -> UIViewController? {
        UIHostingController(
            coder: coder,
            rootView: TermsView(presenter: presenter)
                .environment(\.locale, Locale(identifier: locale.cultureCode()))
        )
    }
}
