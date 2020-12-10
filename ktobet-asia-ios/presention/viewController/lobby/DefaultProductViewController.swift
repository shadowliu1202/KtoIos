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
}

class DefaultProductViewController: UIViewController {

    @IBOutlet private weak var btnIgnore: UIBarButtonItem!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var btnNext : UIButton!
    
    private let rowHeight : CGFloat = 140
    private let segueLobby = "BackToLobby"
    private var viewModel = DI.resolve(DefaultProductViewModel.self)!
    private var disposeBag = DisposeBag()
    private var games : [DefaultProductItem] = {
        let titles = ["體育", "娛樂場", "老虎機", "數字彩"]
        let descs = ["最全的賽事，一但擁有，別無所求", "場地要紅，長龍在手，天下我有", "也許不經意的一次，就在紫禁之巔", "洞察數字的奧秘，牛頓也要扶我"]
        let selected = [false, false, false, false]
        let type : [ProductType] = [.sbk, .casino, .slot, .numbergame]
        var arr = [DefaultProductItem]()
        for idx in 0...3{
            let game = DefaultProductItem(name: titles[idx], desc: descs[idx], selected: selected[idx], type: type[idx])
            arr.append(game)
        }
        return arr
    }()

    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
                
            }).disposed(by: disposeBag)
    }
    
    @IBAction func btnNextPressed(_ sender : UIButton){
        
        guard let item = games.filter({ (element) -> Bool in return element.selected }).first else {
            return
        }
        
        viewModel.saveDefaultProduct(item.type)
            .andThen(viewModel.getPlayerInfo())
            .subscribe(onSuccess: { player in
                self.performSegue(withIdentifier: self.segueLobby, sender: player)
            }, onError: { error in
                
            }).disposed(by: disposeBag)
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
