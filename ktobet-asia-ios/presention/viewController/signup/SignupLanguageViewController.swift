//
//  Register1ViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/10/23.
//

import UIKit
import RxSwift
import RxCocoa
import SharedBu

class SignupLanguageViewController: LandingViewController {
    var barButtonItems: [UIBarButtonItem] = []

    struct LanguageListData {
        var title : String
        var type : SupportLocale
        var selected : Bool
    }
    
    @IBOutlet private weak var naviItem: UINavigationItem!
    @IBOutlet private weak var btnBack: UIBarButtonItem!
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
    
    private var padding = UIBarButtonItem.kto(.text(text: "")).isEnable(false)
    private lazy var login = UIBarButtonItem.kto(.login)
    private var spacing = UIBarButtonItem.kto(.text(text: "|")).isEnable(false)
    private lazy var customService = UIBarButtonItem.kto(.cs(delegate: self, disposeBag: disposeBag))
    
    var languageChangeHandler : (()->())?

    // MARK: Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bind(position: .right, barButtonItems: padding, login, spacing, customService)
        localize()
        reloadLanguageList()
        setupStyle()
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
    
    // MARK: METHOD
    private func localize(){
        login.title = Localize.string("common_login")
        customService.title = Localize.string("customerservice_title")
        labTitle.text = Localize.string("register_step1_title_1")
        labDesc.text = Localize.string("register_step1_title_2")
        labTermsTip.text = Localize.string("register_step1_tips_1")
        btnNext.setTitle(Localize.string("common_next"), for: .normal)
        btnTerms.setTitle(Localize.string("register_step1_tips_1_highlight"), for: .normal)
    }
    
    private func reloadLanguageList(){
        arrLangs = {
            let texts = [Localize.string("register_language_option_chinese"), Localize.string("register_language_option_vietnam")]
            let type = [SupportLocale.China.init(), SupportLocale.Vietnam.init()]
            var arr = [LanguageListData]()
            for idx in 0...1{
                arr.append({
                    let selected : Bool = type[idx].cultureCode() == Localize.getLanguage()
                    let item = LanguageListData(title: texts[idx],
                                                type: type[idx],
                                                selected: selected)
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
        if let termsOfServiceViewController = UIStoryboard(name: "Signup", bundle: nil).instantiateViewController(withIdentifier: "TermsOfServiceViewController") as? TermsOfServiceViewController {
            termsOfServiceViewController.termsPresenter = ServiceTerms(barItemType: .close)
            self.navigationController?.pushViewController(termsOfServiceViewController, animated: true)
        }
    }
    
    @IBAction func btnNextPressed(_ sender : UIButton){
        performSegue(withIdentifier: segueInfo, sender: nil)
    }
    
    @IBAction func btnBackPressed(_ sender : UIButton){
        performSegue(withIdentifier: segueLogin, sender: nil)
    }
    
    func btnLoginPressed() {
        performSegue(withIdentifier: segueLogin, sender: nil)
    }
    
    @IBAction func btnTipPressed(_ sender : UIButton){
        let title = Localize.string("common_tip_title_warm")
        let message = Localize.string("common_tip_content_bind")
        Alert.show(title, message, confirm: nil, cancel: nil)
    }
    
    override func abstracObserverUpdate() {
        self.observerCompulsoryUpdate()
    }
    
    private func didSelectRowAt(indexPath: IndexPath) {
        guard indexPath.row < arrLangs.count else { return }
        for idx in 0..<arrLangs.count{
            arrLangs[idx].selected = indexPath.row == idx
        }
        if let locale = arrLangs.filter({ (data) -> Bool in return data.selected }).first?.type {
            Localize.setLanguage(language: locale)
        }
        localize()
        languageChangeHandler?()
        tableView.reloadData()
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
        cell.didSelectOn = { [weak self] _ in
            self?.didSelectRowAt(indexPath: indexPath)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.didSelectRowAt(indexPath: indexPath)
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
            vc.locale = locale
        }
    }
}

extension SignupLanguageViewController: BarButtonItemable {
    func pressedRightBarButtonItems(_ sender: UIBarButtonItem) {
        switch sender.tag {
        case loginBarBtnId:
            btnLoginPressed()
        default:
            break
        }
    }
}

extension SignupLanguageViewController: CustomServiceDelegate {
    func customServiceBarButtons() -> [UIBarButtonItem]? {
        [spacing, customService]
    }
}
