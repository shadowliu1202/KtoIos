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
        defaultStyle()
        reloadTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: METHOD
    private func localize(){
        labDesc.text = Localize.string("license_warning")
        btnTitle.title = Localize.string("common_service_terms")
    }
    
    private func defaultStyle(){
        view.backgroundColor = UIColor.white
        labDesc.textColor = UIColor.black_two
    }
        
    private func reloadTableView(){
        dataSourceTerms = {
            var arr = [TermsOfService]()
            let titles = [Localize.string("license_definition"),
                          Localize.string("license_agree"),
                          Localize.string("license_modify"),
                          Localize.string("license_gaminginfo_intellectualproperty"),
                          Localize.string("license_condition"),
                          Localize.string("license_register_membership"),
                          Localize.string("license_bet_acceptbet"),
                          Localize.string("license_gamingsoftware_usagerights"),
                          Localize.string("license_transaction_settlement"),
                          Localize.string("license_bouns"),
                          Localize.string("license_promotion_reward"),
                          Localize.string("license_compensation"),
                          Localize.string("license_disclaimer_specialconsideration"),
                          Localize.string("license_termination"),
                          Localize.string("license_linktoexternal"),
                          Localize.string("license_linktobettingsite"),
                          Localize.string("license_addorbreak_gamblingcategories"),
                          Localize.string("license_violation"),
                          Localize.string("license_priority_order"),
                          Localize.string("license_forcemajeure"),
                          Localize.string("license_abstain"),
                          Localize.string("license_severability"),
                          Localize.string("license_law_jurisdiction")]
            let contents = [Localize.string("license_definition_content"),
                            Localize.string("license_agree_content"),
                            Localize.string("license_modify_content"),
                            Localize.string("license_gaminginfo_intellectualproperty_content"),
                            Localize.string("license_condition_content"),
                            Localize.string("license_register_membership_content"),
                            Localize.string("license_bet_acceptbet_content"),
                            Localize.string("license_gamingsoftware_usagerights_content"),
                            Localize.string("license_transaction_settlement_content"),
                            Localize.string("license_bouns_content"),
                            Localize.string("license_promotion_reward_content"),
                            Localize.string("license_compensation_content"),
                            Localize.string("license_disclaimer_specialconsideration_content"),
                            Localize.string("license_termination_content"),
                            Localize.string("license_linktoexternal_content"),
                            Localize.string("license_linktobettingsite_content"),
                            Localize.string("license_addorbreak_gamblingcategories_content"),
                            Localize.string("license_violation_content"),
                            Localize.string("license_priority_order_content"),
                            Localize.string("license_forcemajeure_content"),
                            Localize.string("license_abstain_content"),
                            Localize.string("license_severability_content"),
                            Localize.string("license_law_jurisdiction_content")]
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
