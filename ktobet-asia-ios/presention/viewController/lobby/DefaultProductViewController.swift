import UIKit
import RxSwift
import RxCocoa
import share_bu

struct DefaultProductItem {
    var name = ""
    var desc = ""
    var selected = false
    var type : ProductType = .none
    var selectImg : UIImage
    var unselectImg : UIImage
}

class DefaultProductViewController: UIViewController {
    @IBOutlet private weak var btnIgnore: UIBarButtonItem!
    @IBOutlet private weak var btnInfo : UIButton!
    @IBOutlet private weak var labTitle : UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var btnNext : UIButton!
    
    private let rowHeight : CGFloat = 116
    private let segueLobby = "BackToLobby"
    private var viewModel = DI.resolve(DefaultProductViewModel.self)!
    private var disposeBag = DisposeBag()
    private var games : [DefaultProductItem] = {
        
        let titles = [Localize.string("landing_sportsbook_title"),
                      Localize.string("landing_casino_title"),
                      Localize.string("landing_slot_title"),
                      Localize.string("common_keno")]
        let descs = [Localize.string("profile_defaultproduct_sportsbook_description"),
                     Localize.string("profile_defaultproduct_casino_description"),
                     Localize.string("profile_defaultproduct_slot_description"),
                     Localize.string("profile_defaultproduct_keno_description")]
        let selected = [false, false, false, false]
        let type : [ProductType] = [.sbk, .casino, .slot, .numbergame]
        let selectImg = [UIImage(named: "(375)SBK-Select"),
                         UIImage(named: "(375)Casino-Select"),
                         UIImage(named: "(375)Slot-Select"),
                         UIImage(named: "(375)Number Game-Select")]
        let unselectImg = [UIImage(named: "(375)SBK-Unselect"),
                           UIImage(named: "(375)Casino-Unselect"),
                           UIImage(named: "(375)Slot-Unselect"),
                           UIImage(named: "(375)Number Game-Unselect")]
        var arr = [DefaultProductItem]()
        for idx in 0...3{
            let game = DefaultProductItem(name: titles[idx],
                                          desc: descs[idx],
                                          selected: selected[idx],
                                          type: type[idx],
                                          selectImg: selectImg[idx]!,
                                          unselectImg: unselectImg[idx]!)
            arr.append(game)
        }
        return arr
    }()
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        localize()
        defaultStyle()
    }
    
    // MARK: METHOD
    private func localize(){
        btnIgnore.title = Localize.string("common_skip")
        btnNext.setTitle(Localize.string("common_next"), for: .normal)
        labTitle.text = Localize.string("profile_defaultproduct_title")
    }
    
    private func defaultStyle(){
        self.btnNext.layer.cornerRadius = 9
        self.btnNext.layer.masksToBounds = true
        btnNext.isValid = false
    }
    
    // MARK: BUTTON ACTION
    @IBAction func btnIgnorePressed(_ sender : UIButton){
        viewModel.saveDefaultProduct(.sbk)
            .andThen(viewModel.getPlayerInfo())
            .subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: { player in
                DispatchQueue.main.async {
                    NavigationManagement.sharedInstance.goTo(storyboard: "Game", viewControllerId: "SBKNavigationController")
                }
            }, onError: { error in
                self.handleUnknownError(error)
            }).disposed(by: disposeBag)
    }
    
    @IBAction func btnNextPressed(_ sender : UIButton){
        guard let item = games.filter({ (element) -> Bool in return element.selected }).first else {
            return
        }
        viewModel
            .saveDefaultProduct(item.type)
            .andThen(viewModel.getPlayerInfo())
            .subscribe(onSuccess: { _ in
                NavigationManagement.sharedInstance.goTo(productType: item.type)
            }, onError: { error in
                self.handleUnknownError(error)
            }).disposed(by: disposeBag)
    }
    
    @IBAction func btnInfoPressed(_ sender: UIButton){
        let title = Localize.string("common_tip_title_warm")
        let message = Localize.string("profile_defaultproduct_description")
        Alert.show(title, message, confirm: nil, cancel: nil)
    }
}

// MARK: TABLE VIEW
extension DefaultProductViewController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        btnNext.isValid = true
        for idx in 0..<games.count{
            games[idx].selected = idx == indexPath.row
        }
        tableView.reloadData()
    }
}

extension DefaultProductViewController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return games.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = games[indexPath.row]
        let identifier = String(describing: DefaultProductCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! DefaultProductCell
        cell.setup(item)
        return cell
    }
}
