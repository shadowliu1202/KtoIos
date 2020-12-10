//
//  SideBarViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/5.
//

import UIKit
import share_bu

class SideBarViewController: UIViewController {
    
    struct ProductItem {
        var title = ""
        var type = ProductType.none
    }
    
    enum FeatureType : String {
        case withdraw = "提現"
        case diposit = "充值"
        case callService = "呼叫客服"
        case logout = "登出"
    }
    
    @IBOutlet private weak var btnGift: UIBarButtonItem!
    @IBOutlet private weak var btnNotification: UIBarButtonItem!
    @IBOutlet private weak var btnClose: UIBarButtonItem!
    @IBOutlet private weak var listProduct: UICollectionView!
    @IBOutlet private weak var listFeature: UITableView!
    @IBOutlet private weak var constraintListProductHeight: NSLayoutConstraint!
    @IBOutlet private weak var constraintListFeatureHeight: NSLayoutConstraint!
    
    private let arrProducts : [ProductItem] = {
        var titles = ["體育", "娛樂場", "老虎機", "數字彩"]
        var type : [ProductType] = [.sbk, .casino, .slot, .numbergame]
        var arr = [ProductItem]()
        for idx in 0...3{
            let item = ProductItem(title: titles[idx], type: type[idx])
            arr.append(item)
        }
        return arr
    }()
    private let arrFeature : [FeatureType] = [.diposit, .withdraw, .callService, .logout]
    var productDidSelected : ((ProductType)->Void)?
    
    // MARK: LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        listFeature.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        listProduct.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        
        listProduct.collectionViewLayout = {
            let space = CGFloat(20)
            let width = (UIScreen.main.bounds.size.width - space * 5) / 4
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
            flowLayout.itemSize = CGSize(width: width, height: width)
            flowLayout.minimumLineSpacing = space
            flowLayout.minimumInteritemSpacing = space
            return flowLayout
        }()
        listProduct.reloadData()
        listFeature.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: BUTTON EVENT
    @IBAction func btnClosePressed(_ sender : UIButton)  {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: KVO
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize", let newvalue = change?[.newKey] {
            if let obj = object as? UICollectionView , obj == listProduct{
                constraintListProductHeight.constant = (newvalue as! CGSize).height
            }
            if let obj = object as? UITableView, obj == listFeature{
                constraintListFeatureHeight.constant = (newvalue as! CGSize).height
            }
        }
    }
    
}

extension SideBarViewController : UICollectionViewDataSource, UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrProducts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = String(describing: ProductItemCell.self)
        let item = arrProducts[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! ProductItemCell
        cell.setup(item.title)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = arrProducts[indexPath.row]
        dismiss(animated: true) {
            self.productDidSelected?(item.type)
        }
    }
}

extension SideBarViewController : UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrFeature.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = String(describing: FeatureItemCell.self)
        let item = arrFeature[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! FeatureItemCell
        cell.setup(item.rawValue)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
