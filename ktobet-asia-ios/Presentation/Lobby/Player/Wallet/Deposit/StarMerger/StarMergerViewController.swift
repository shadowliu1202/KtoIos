
import sharedbu
import SwiftUI
import UIKit

class StarMergerViewController:
    APPViewController,
    SwiftUIConverter
{
    let viewModel = Injectable.resolve(StarMergerViewModelImpl.self)!
    let httpClient = Injectable.resolve(HttpClient.self)!
    var link: CommonDTO.WebPath? {
        viewModel.paymentLink
    }

    let paymentGatewayID: String

    init(paymentGatewayID: String) {
        self.paymentGatewayID = paymentGatewayID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)

        addSubView(
            StarMergerView(viewModel: viewModel, { [unowned self] in
                let url = self.httpClient.host.absoluteString + $0!.path
                self.navigationController?
                    .pushViewController(DepositThirdPartWebViewController(url: url), animated: true)
            }),
            to: view)
    }
}
