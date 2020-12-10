//
//  SocketTestViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/9.
//

import UIKit
import RxSwift


class SocketTestViewController: UIViewController {

    private var viewModel = DI.resolve(TestViewModel.self)!
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        viewModel.getToken()
            .subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: {token in
                self.viewModel.customServiceConnect(token)
            }, onError: {error in
                
            }).disposed(by: disposeBag)
    }
    
    deinit {
        viewModel.customServiceDisconnect()
    }
}
