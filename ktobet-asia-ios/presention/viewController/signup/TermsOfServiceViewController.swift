//
//  TermsOfServiceViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/23.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

struct TermsOfService {
    var title = ""
    var content = ""
    var selected = false
}

class TermsOfServiceViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var btnTitle : UIBarButtonItem!
    @IBOutlet private weak var labDesc : UILabel!
    @IBOutlet private weak var scrollView : UIScrollView!
    @IBOutlet private weak var tableView : UITableView!
    @IBOutlet private weak var naviItem: UINavigationItem!
    @IBOutlet private weak var constraintTableViewHeight : NSLayoutConstraint!
    
    private let segueLanguage = "BackToLanguage"
    private var dataSourceTerms : [TermsOfService] = []
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        localize()
        reloadTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: METHOD
    private func localize(){
        labDesc.text = Localize.string("Warning")
        btnTitle.title = Localize.string("service_terms")
    }
    
    private func reloadTableView(){
        dataSourceTerms = {
            var arr = [TermsOfService]()
            let titles = [Localize.string("Definition"),
                          Localize.string("Agree"),
                          Localize.string("Modify"),
                          Localize.string("GamingInfo_IntellectualProperty"),
                          Localize.string("Condition"),
                          Localize.string("Register_Membership"),
                          Localize.string("Bet_AcceptBet"),
                          Localize.string("GamingSoftware_UsageRights"),
                          Localize.string("Transaction_Settlement"),
                          Localize.string("Bouns"),
                          Localize.string("Promotion_Reward"),
                          Localize.string("Compensation"),
                          Localize.string("Disclaimer_SpecialConsideration"),
                          Localize.string("Termination"),
                          Localize.string("LinkToExternal"),
                          Localize.string("LinkToBettingSite"),
                          Localize.string("AddOrBreak_GamblingCategories"),
                          Localize.string("Violation"),
                          Localize.string("Priority_Order"),
                          Localize.string("ForceMajeure"),
                          Localize.string("Abstain"),
                          Localize.string("Severability"),
                          Localize.string("Law_Jurisdiction")]
            let contents = [Localize.string("Definition_Content"),
                            Localize.string("Agree_Content"),
                            Localize.string("Modify_Content"),
                            Localize.string("GamingInfo_IntellectualProperty_Content"),
                            Localize.string("Condition_Content"),
                            Localize.string("Register_Membership_Content"),
                            Localize.string("Bet_AcceptBet_Content"),
                            Localize.string("GamingSoftware_UsageRights_Content"),
                            Localize.string("Transaction_Settlement_Content"),
                            Localize.string("Bouns_Content"),
                            Localize.string("Promotion_Reward_Content"),
                            Localize.string("Compensation_Content"),
                            Localize.string("Disclaimer_SpecialConsideration_Content"),
                            Localize.string("Termination_Content"),
                            Localize.string("LinkToExternal_Content"),
                            Localize.string("LinkToBettingSite_Content"),
                            Localize.string("AddOrBreak_GamblingCategories_Content"),
                            Localize.string("Violation_Content"),
                            Localize.string("Priority_Order_Content"),
                            Localize.string("ForceMajeure_Content"),
                            Localize.string("Abstain_Content"),
                            Localize.string("Severability_Content"),
                            Localize.string("Law_Jurisdiction_Content")]
            for idx in 0..<titles.count{
                let term = TermsOfService.init(title: titles[idx], content: contents[idx], selected: false)
                arr.append(term)
            }
            return arr
        }()
        reloadTableViewHeight()
    }
    
    private func reloadTableViewHeight(){
        constraintTableViewHeight.constant = CGFloat.greatestFiniteMagnitude
        tableView.reloadData()
        tableView.layoutIfNeeded()
        constraintTableViewHeight.constant = tableView.contentSize.height
    }
    
    // MARK: BUTTON ACTION
    @IBAction func btnBackPressed(_ sender : UIButton){
        performSegue(withIdentifier: segueLanguage, sender: nil)
    }
}

extension TermsOfServiceViewController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSourceTerms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: TermsOfServiceCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! TermsOfServiceCell
        cell.setup(dataSourceTerms[indexPath.row])
        return cell
    }
}

extension TermsOfServiceViewController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dataSourceTerms[indexPath.row].selected = !dataSourceTerms[indexPath.row].selected
        tableView.reloadItemsAtIndexPaths([indexPath], animationStyle: .automatic)
        reloadTableViewHeight()
    }
}

extension TermsOfServiceViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
}
