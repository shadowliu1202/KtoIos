//
//  MainDebugViewController.swift
//  ktobet-asia-ios
//
//  Created by LeoOnHiggstar on 2021/3/15.
//

import UIKit
import RxSwift
import RxCocoa

struct DebugData {
    var callbackTime: String?
    var url: String?
    var headers: String?
    var body: String?
    var error: String?
    var response: String?
}

class MainDebugViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var itemViewHeight: NSLayoutConstraint!
    var cancelHandle: (() -> Void)?
    
    private var debugDatas = BehaviorRelay<[DebugData]>(value: [])
    private var debugLogs: [String] = []

    private lazy var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupBinding()
        loadData(DI.resolve(HttpClient.self)!.debugDatas.reversed())
    }
    
    private func setCell(cell:MainDebugDataCell, callbackTime: String?, url: String?, headers: String?, body: String?, error: String?, response: String?) {
        
        cell.callbackTimeRowStackView.isHidden = callbackTime == nil
        cell.urlRowStackView.isHidden = url == nil
        cell.headersRowStackView.isHidden = headers == nil
        cell.bodyRowStackView.isHidden = body == nil
        
        cell.errorImageView.isHidden = error == nil

        cell.callbackTimeLabel.text = callbackTime
        cell.urlLabel.text = url
        cell.headersLabel.text = headers
        cell.responseLabel.textColor = error != nil ? UIColor(hex: 0xff0000) : UIColor(hex: 0x000000)
        cell.responseLabel.text = error != nil ? error : response
        cell.bodyLabel.text = body
        
    }

    private func setupBinding() {
        self.debugDatas.asDriver().drive(tableView.rx.items(cellIdentifier: "MainDebugDataCell", cellType: MainDebugDataCell.self)) { [weak self] row, item, cell in
            self?.setCell(cell: cell, callbackTime: item.callbackTime, url: item.url, headers: item.headers, body: item.body, error: item.error, response: item.response)
        }.disposed(by: self.disposeBag)
        
        self.tableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
            self?.tableView.deselectRow(at: indexPath, animated: true)
            guard !(self?.debugLogs.isEmpty ?? true), let log = self?.debugLogs[indexPath.row] else { return }
            self?.presentActivityView(with: [log])
        }).disposed(by: self.disposeBag)
        
        self.cancelButton.rx.touchUpInside.subscribe(onNext: { [weak self] _ in
            self?.cancelHandle?()
        }).disposed(by: self.disposeBag)
    }
    
    private func loadData(_ logs: [DebugData]) {
        debugDatas.accept(logs)
    }
    
    private func presentActivityView(with shareItem: [Any],
                             excluded types: [UIActivity.ActivityType]? = nil,
                             completionWithItemsHandler: UIActivityViewController.CompletionWithItemsHandler? = nil) {
        let activityViewController = UIActivityViewController(activityItems: shareItem, applicationActivities: nil)
        activityViewController.excludedActivityTypes = types
        activityViewController.completionWithItemsHandler = completionWithItemsHandler
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    deinit {
        print("\(type(of: self)) deinit")
    }
}

class MainDebugDataCell: UITableViewCell {
    @IBOutlet weak var callbackTimeRowStackView: UIStackView!
    @IBOutlet weak var urlRowStackView: UIStackView!
    @IBOutlet weak var headersRowStackView: UIStackView!
    @IBOutlet weak var bodyRowStackView: UIStackView!
    @IBOutlet weak var responseRowStackView: UIStackView!
    
    @IBOutlet weak var errorImageView: UIImageView!
    @IBOutlet weak var callbackTimeLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var headersLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var responseLabel: UILabel!
}
