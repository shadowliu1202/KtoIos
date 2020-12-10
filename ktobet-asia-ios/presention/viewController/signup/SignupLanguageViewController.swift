//
//  Register1ViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/23.
//

import UIKit
import RxSwift
import RxCocoa
import share_bu


struct LanguageListData{
    var title : String?
    var type : SupportLocale?
    var selected : Bool?
}

class SignupLanguageViewController: UIViewController{
    
    @IBOutlet private weak var naviItem: UINavigationItem!
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var btnNext : UIButton!
    @IBOutlet private weak var btnTermsOfService : UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var constraintTableHeight: NSLayoutConstraint!
    
    private let segueLogin = "BackToLogin"
    private let segueInfo = "GoToInfo"
    private let segueTerms = "GoToTermsOfService"
    private let rowHeight : CGFloat = 72

    private var disposeBag = DisposeBag()
    lazy private var arrLangs : [LanguageListData] = {
        let texts = ["简体中文 + 人民币", "Người việt nam + đồng"]
        let type = [SupportLocale.China(), SupportLocale.Vietnam()]
        let selected = [true, false]
        var arr = [LanguageListData]()
        for idx in 0...1{
            arr.append({
                var item = LanguageListData()
                item.title = texts[idx]
                item.type = type[idx]
                item.selected = selected[idx]
                return item
            }())
        }
        return arr
    }()

    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        constraintTableHeight.constant = rowHeight * CGFloat(arrLangs.count)
    }
    
    // MARK: BUTTON ACTION
    @IBAction func btnTermsOfServicePressed(_ sender : UIButton){
        performSegue(withIdentifier: segueTerms, sender: nil)
    }
    
    @IBAction func btnNextPressed(_ sender : UIButton){
        performSegue(withIdentifier: segueInfo, sender: nil)
    }
    
    @IBAction func btnBackPressed(_ sender : UIButton){
        performSegue(withIdentifier: segueLogin, sender: nil)
    }
}


extension SignupLanguageViewController : UITableViewDelegate, UITableViewDataSource{
    // MARK: TABLE VIEW
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrLangs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: LanguageAndCurrencyCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! LanguageAndCurrencyCell
        cell.setup(arrLangs[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < arrLangs.count else { return }
        for idx in 0..<arrLangs.count{
            arrLangs[idx].selected = indexPath.row == idx
        }
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
}

extension SignupLanguageViewController{
    // MARK: PAGE ACTION
    @IBAction func backToLanguageList(segue: UIStoryboardSegue){}
    override func unwind(for unwindSegue: UIStoryboardSegue, towards subsequentVC: UIViewController) {}
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? SignupUserinfoViewController,
           let locale = arrLangs.filter({ (data) -> Bool in return data.selected! }).first?.type{
            vc.locale = locale
        }
    }
    
    
}
