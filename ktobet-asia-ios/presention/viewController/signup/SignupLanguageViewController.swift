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




class SignupLanguageViewController: UIViewController{
    
    enum Language {
        case China
        case Vietnam
    }
    
    struct LanguageListData{
        var title : String
        var type : Language
        var selected : Bool
    }
    
    @IBOutlet private weak var naviItem: UINavigationItem!
    @IBOutlet private weak var btnBack: UIBarButtonItem!
    @IBOutlet private weak var btnRegist : UIBarButtonItem!
    @IBOutlet private weak var btnNext : UIButton!
    @IBOutlet private weak var btnTerms : UIButton!
    @IBOutlet private weak var labTitle : UILabel!
    @IBOutlet private weak var labDesc : UILabel!
    @IBOutlet private weak var labTermsTip : UILabel!
    @IBOutlet private weak var btnTermsOfService : UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var constraintTableHeight: NSLayoutConstraint!
    
    private let segueLogin = "BackToLogin"
    private let segueInfo = "GoToInfo"
    private let segueTerms = "GoToTermsOfService"
    private let rowHeight : CGFloat = 72
    private let rowSpace : CGFloat = 12

    private var disposeBag = DisposeBag()
    private var arrLangs : [LanguageListData] = []

    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        localize()
        reloadLanguageList()
        setupStyle()
    }
    
    // MARK: METHOD
    private func localize(){
        labTitle.text = Localize.string("Step1_Title_1")
        labDesc.text = Localize.string("Step2_Title_2")
        labTermsTip.text = Localize.string("Step1_Tips_1")
        btnNext.setTitle(Localize.string("Next"), for: .normal)
        btnTerms.setTitle(Localize.string("Step1_Tips_1_Highlight"), for: .normal)
        btnRegist.title = Localize.string("Login")
    }
    
    private func reloadLanguageList(){
        arrLangs = {
            let texts = [Localize.string("language_option_chinese"), Localize.string("language_option_vietnam")]
            let type : [Language] = [.China, .Vietnam]
            let selected = [true, false]
            var arr = [LanguageListData]()
            for idx in 0...1{
                arr.append({
                    let item = LanguageListData(title: texts[idx],
                                                type: type[idx],
                                                selected: selected[idx])
                    return item
                }())
            }
            return arr
        }()
        constraintTableHeight.constant = {
            var height = rowHeight * CGFloat(arrLangs.count)
            if height > 12 { height -= 12 }
            return height
        }()
    }
    
    private func setupStyle(){
        naviItem.titleView = UIImageView(image: UIImage(named: "KTO (D)"))
        btnNext.layer.cornerRadius = 9
        btnNext.layer.masksToBounds = true
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
    
    @IBAction func btnLoginPressed(_ sender : UIButton){
        performSegue(withIdentifier: segueLogin, sender: nil)
    }
    
    @IBAction func btnTipPressed(_ sender : UIButton){
        let title = Localize.string("tip_title_warm")
        let message = Localize.string("tip_content_bind")
        let confirm = Localize.string("Determine")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: confirm, style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
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
           let locale = arrLangs.filter({ (data) -> Bool in return data.selected }).first?.type{
            switch locale {
            case .China:
                Localize.setLanguage(language: .ZH)
                vc.locale = SupportLocale.China()
            case .Vietnam:
                Localize.setLanguage(language: .VI)
                vc.locale = SupportLocale.Vietnam()
            }
        }
    }
}
