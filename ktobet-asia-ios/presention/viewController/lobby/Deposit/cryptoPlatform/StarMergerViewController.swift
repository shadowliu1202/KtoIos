
import UIKit
import SwiftUI
import SharedBu


class StarMergerViewController: APPViewController {
    static let segueIdentifier = "toStarMergerViewController"
    
    let viewModel = DI.resolve(StarMergerViewModelImpl.self)!
    let httpClient = DI.resolve(HttpClient.self)!
    var link: CommonDTO.WebPath? {
        viewModel.paymentLink
    }
    var paymentGatewayID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back)
    }

    @IBSegueAction func toStarMergerView(_ coder: NSCoder) -> UIViewController? {
        return UIHostingController(coder: coder, rootView: StarMergerView(viewModel: viewModel, { webPath in
            let url = self.httpClient.host.absoluteString + webPath!.path
            NavigationManagement.sharedInstance.viewController.performSegue(withIdentifier: DepositThirdPartWebViewController.segueIdentifier, sender: url)
        }))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == DepositThirdPartWebViewController.segueIdentifier {
            if let dest = segue.destination as? DepositThirdPartWebViewController {
                dest.url = sender as? String
            }
        }
    }
}
