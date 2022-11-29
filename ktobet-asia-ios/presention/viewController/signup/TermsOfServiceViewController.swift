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
import SharedBu

enum TermsType {
    case termsOfService(BarItemType)
    case promotionSecurityPrivacy
    case gamblingResponsibility
}

class TermsOfServiceViewController: CommonViewController, UIScrollViewDelegate {
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var btnTitle : UIBarButtonItem!
    @IBOutlet private weak var labTitle : UILabel!
    @IBOutlet private weak var labDesc : UILabel!
    @IBOutlet private weak var scrollView : UIScrollView!
    @IBOutlet private weak var tableView : UITableView!
    @IBOutlet private weak var naviItem: UINavigationItem!
    @IBOutlet private weak var constraintTableViewHeight : NSLayoutConstraint!
    
    var termsPresenter: TermsPresenter!
    
    private var dataSourceTerms : [TermsOfService] = []
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    
    private func initUI(){
        labDesc.textColor = UIColor.black131313
        tableView.addTopBorder(size: 1, color: UIColor.black)
        let navigationTitle: String = termsPresenter.navigationTitle
        let naviBarBtn: BarItemType = termsPresenter.barItemType
        let description: String = termsPresenter.description
        NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: naviBarBtn)
        labTitle.text = navigationTitle
        labDesc.text = description
        dataSourceTerms = termsPresenter.dataSourceTerms
        reloadTableViewHeight()
    }
    
    private func reloadTableViewHeight(){
        constraintTableViewHeight.constant = CGFloat.greatestFiniteMagnitude
        tableView.reloadData()
        tableView.layoutIfNeeded()
        constraintTableViewHeight.constant = tableView.contentSize.height
    }
}

extension TermsOfServiceViewController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSourceTerms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: TermsOfServiceCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! TermsOfServiceCell
        cell.setup(dataSourceTerms[indexPath.row], isLatestRow: dataSourceTerms.count - 1 == indexPath.row)
        return cell
    }
}

extension TermsOfServiceViewController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dataSourceTerms[indexPath.row].selected = !dataSourceTerms[indexPath.row].selected
        tableView.reloadItemsAtIndexPaths([indexPath], animationStyle: .none)
        reloadTableViewHeight()
    }
}

extension TermsOfServiceViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
}
