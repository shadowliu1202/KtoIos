//
//  DefaultSettingViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/3.
//

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
        
        let titles = [Localize.string("Sportsbook"),
                      Localize.string("Casino"),
                      Localize.string("Slot"),
                      Localize.string("Keno")]
        let descs = [Localize.string("DefaultProduct_Sportsbook_description"),
                     Localize.string("DefaultProduct_Casino_description"),
                     Localize.string("DefaultProduct_Slot_description"),
                     Localize.string("DefaultProduct_Keno_description")]
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
        btnIgnore.title = Localize.string("Skip")
        btnNext.setTitle(Localize.string("Next"), for: .normal)
        labTitle.text = Localize.string("DefaultProduct_Title")
    }
    
    private func defaultStyle(){
        self.btnNext.layer.cornerRadius = 9
        self.btnNext.layer.masksToBounds = true
    }
    
    // MARK: BUTTON ACTION
    @IBAction func btnIgnorePressed(_ sender : UIButton){
        
        viewModel.saveDefaultProduct(.sbk)
            .andThen(viewModel.getPlayerInfo())
            .subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: { player in
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: self.segueLobby, sender: player)
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
            .subscribe(onSuccess: { player in
                self.performSegue(withIdentifier: self.segueLobby, sender: player)
            }, onError: { error in
                self.handleUnknownError(error)
            }).disposed(by: disposeBag)
    }
    
    @IBAction func btnInfoPressed(_ sender: UIButton){
        let title = Localize.string("tip_title_warm")
        let message = Localize.string("DefaultProduct_Description")
        Alert.show(title, message, confirm: nil, cancel: nil)
    }
}

// MARK: PAGE CHANGE
extension DefaultProductViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let lobby = segue.destination as? LobbyViewController,
           let player = sender as? Player{
            lobby.player = player
        }
    }
}

// MARK: TABLE VIEW
extension DefaultProductViewController : UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return rowHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
