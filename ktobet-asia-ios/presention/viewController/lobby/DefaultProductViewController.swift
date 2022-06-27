import UIKit
import RxSwift
import RxCocoa
import SharedBu

class DefaultProductViewController: LobbyViewController {
    @IBOutlet private weak var btnIgnore: UIBarButtonItem!
    @IBOutlet private weak var btnInfo : UIButton!
    @IBOutlet private weak var labTitle : UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var btnNext : UIButton!
    
    private let segueLobby = "BackToLobby"
    private var viewModel = DI.resolve(DefaultProductViewModel.self)!
    private let playerLocaleConfiguration = DI.resolve(PlayerLocaleConfiguration.self)!
    private var disposeBag = DisposeBag()
    private var games: [ProductType] = [.sbk, .casino, .slot, .numbergame]
    private var currentSelectGame: ProductType?
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        defaultStyle()
    }
    
    // MARK: METHOD
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
                    NavigationManagement.sharedInstance.goTo(productType: .sbk)
                }
            }, onError: { error in
                self.handleErrors(error)
            }).disposed(by: disposeBag)
    }
    
    @IBAction func btnNextPressed(_ sender : UIButton){
        guard let item = currentSelectGame else {
            return
        }
        viewModel
            .saveDefaultProduct(item)
            .andThen(viewModel.getPlayerInfo())
            .subscribe(onSuccess: { _ in
                NavigationManagement.sharedInstance.goTo(productType: item)
            }, onError: { error in
                self.handleErrors(error)
            }).disposed(by: disposeBag)
    }
    
    @IBAction func btnInfoPressed(_ sender: UIButton){
        let title = Localize.string("common_tip_title_warm")
        let message = Localize.string("profile_defaultproduct_description")
        Alert.show(title, message, confirm: nil, cancel: nil)
    }
}

extension DefaultProductViewController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        btnNext.isValid = true
        currentSelectGame = games[indexPath.row]
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
        cell.setup(item, playerLocaleConfiguration.getSupportLocale(), currentSelectGame)
        return cell
    }
}
