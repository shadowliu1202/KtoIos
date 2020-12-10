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

class TermsOfServiceViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet private weak var tableView : UITableView!
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var naviItem: UINavigationItem!
    
    private let segueLanguage = "BackToLanguage"
    
    private var disposeBag = DisposeBag()
    private var viewModel = DI.resolve(TermsOfServiceViewModel.self)!
    
    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        setViewModel()
    }
    
    // MARK: Method
    func setUI()  {
               
        naviItem.title = "服务条款"
        // Table View
        let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<Int, TermsOfService>>(
            configureCell: { (_, tv, indexPath, element) in
                switch indexPath.section{
                case 0: return {
                    let identifier = String(describing: TermsOfServiceHeader.self)
                    let cell = tv.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! TermsOfServiceHeader
                    cell.setup(element)
                    return cell
                }()
                case 1: return {
                    let identifier = String(describing: TermsOfServiceCell.self)
                    let cell = tv.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! TermsOfServiceCell
                    cell.setup(element)
                    return cell
                }()
                default: return UITableViewCell()
                }
            })
        viewModel.repoTerms.bind(to: tableView.rx.items(dataSource: dataSource)).disposed(by: disposeBag)
        
        tableView.rx.itemSelected.filter { (indexPath) -> Bool in
            return indexPath.section != 0
        }.subscribe(onNext: {indexPath in
            self.viewModel.termSelected(indexPath.section, indexPath.row)
        }).disposed(by: disposeBag)
        
        tableView.rx
        .setDelegate(self)
        .disposed(by: disposeBag)
        
        // button Event
        btnBack.rx.tap.subscribe(onNext:{_ in
            self.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
    }
    
    func setViewModel(){
        viewModel.repoTerms.subscribe(onNext: {(sectionModel) in
            self.tableView.reloadData()
        }).disposed(by: disposeBag)
    }
    
    // MARK: BUTTON ACTION
    @IBAction func btnBackPressed(_ sender : UIButton){
        performSegue(withIdentifier: segueLanguage, sender: nil)
    }
}

extension TermsOfServiceViewController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

extension TermsOfServiceViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
}
