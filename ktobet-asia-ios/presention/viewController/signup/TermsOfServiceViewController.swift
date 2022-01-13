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

struct TermsOfService {
    var title = ""
    var content = ""
    var selected = false
}

enum TermsType {
    case termsOfService
    case promotionSecurityPrivacy
}

class TermsOfServiceViewController: LandingViewController, UIScrollViewDelegate {
    
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var btnTitle : UIBarButtonItem!
    @IBOutlet private weak var labDesc : UILabel!
    @IBOutlet private weak var scrollView : UIScrollView!
    @IBOutlet private weak var tableView : UITableView!
    @IBOutlet private weak var naviItem: UINavigationItem!
    @IBOutlet private weak var constraintTableViewHeight : NSLayoutConstraint!
    
    var termsType: TermsType = .termsOfService
    
    private let segueLanguage = "BackToLanguage"
    private var dataSourceTerms : [TermsOfService] = []
    private var viewModel = DI.resolve(TermsViewModel.self)!
    private var disposeBag = DisposeBag()
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultStyle()
        reloadTableView()

    }
    
    private func defaultStyle(){
        labDesc.textColor = UIColor.black_two
    }
    
    private func reloadTableView() {
        viewModel.initLocale().subscribe {[weak self] in
            guard let self = self else { return }
            switch self.termsType {
            case .termsOfService:
                NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .close, leftItemTitle: Localize.string("common_service_terms"))
                self.createTermsOfService()
            case .promotionSecurityPrivacy:
                NavigationManagement.sharedInstance.addBarButtonItem(vc: self, barItemType: .back, leftItemTitle: Localize.string("common_privacy_terms"))
                self.createPromotionSecurityprivacy()
            }
        } onError: {[weak self] error in
            self?.handleErrors(error)
        }.disposed(by: disposeBag)
    }
    
    private func createTerms(localization: ILocalizationData, key: String) -> String {
        localization.data[key] ?? ""
    }
    
    private func createTermsOfService() {
        viewModel.createPromotionSecurityprivacy().subscribe {[weak self] data in
            self?.dataSourceTerms = data
            self?.dataSourceTerms.remove(at: 0)
            self?.labDesc.text = data.first?.content
            self?.reloadTableViewHeight()
        } onError: {[weak self] error in
            self?.handleErrors(error)
        }.disposed(by: disposeBag)
    }
    
    private func createPromotionSecurityprivacy() {
        viewModel.getPrivacyTerms().subscribe {[weak self] data in
            self?.dataSourceTerms = data
            self?.dataSourceTerms.remove(at: 0)
            self?.labDesc.text = data.first?.content
            self?.reloadTableViewHeight()
        } onError: {[weak self] error in
            self?.handleErrors(error)
        }.disposed(by: disposeBag)
    }
    
    private func reloadTableViewHeight(){
        constraintTableViewHeight.constant = CGFloat.greatestFiniteMagnitude
        tableView.reloadData()
        tableView.layoutIfNeeded()
        constraintTableViewHeight.constant = tableView.contentSize.height
    }
    
    // MARK: BUTTON ACTION
    @IBAction func btnBackPressed(_ sender : UIButton){
        switch termsType {
        case .termsOfService:
            performSegue(withIdentifier: segueLanguage, sender: nil)
        case .promotionSecurityPrivacy:
            NavigationManagement.sharedInstance.popViewController()
        }
    }
    
    override func abstracObserverUpdate() { }
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
        tableView.reloadItemsAtIndexPaths([indexPath], animationStyle: .none)
        reloadTableViewHeight()
    }
}

extension TermsOfServiceViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
}
