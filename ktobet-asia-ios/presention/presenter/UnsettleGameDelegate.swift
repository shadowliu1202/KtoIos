import UIKit

typealias UnsettleHelper = UIViewController & ProductGoWebGameVCProtocol & UnsettleTableViewDelegate & UITableViewDelegate & WebGameViewCallback

protocol UnsettleTableViewDelegate {
    func gameId(at indexPath: IndexPath) -> Int32
    func gameName(at indexPath: IndexPath) -> String
}

class UnsettleGameDelegate : NSObject {
    weak var helper: UnsettleHelper?
    init(_ vc: UnsettleHelper) {
        self.helper = vc
    }
}

extension UnsettleGameDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let helper = helper else { return }
        let storyboard = UIStoryboard(name: "Product", bundle: nil)
        let navi = storyboard.instantiateViewController(withIdentifier: "GameNavigationViewController") as! UINavigationController
        if let gameVc = navi.viewControllers.first as? GameWebViewViewController {
            gameVc.gameId = helper.gameId(at: indexPath)
            gameVc.gameName = helper.gameName(at: indexPath)
            gameVc.viewModel = helper.getProductViewModel()
            gameVc.delegate = helper
            navi.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
            helper.present(navi, animated: true, completion: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        helper?.tableView?(tableView, heightForHeaderInSection: section) ?? 58
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        helper?.tableView?(tableView, heightForRowAt: indexPath) ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        helper?.tableView?(tableView, heightForFooterInSection: section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        helper?.tableView?(tableView, viewForHeaderInSection: section)
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        helper?.tableView?(tableView, willDisplayHeaderView: view, forSection: section)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        helper?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath)
    }
}
