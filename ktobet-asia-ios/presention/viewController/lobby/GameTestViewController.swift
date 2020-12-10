//
//  TestViewController.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/5.
//

import UIKit
import WebKit
import RxSwift

class GameTestViewController: UIViewController {
    
    @IBOutlet private weak var webview : WKWebView!
    private var viewModel = DI.resolve(TestViewModel.self)!
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for cookie in self.viewModel.getCookies(){
            webview.configuration.websiteDataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
        }
        
        viewModel.getGameUrl()
            .subscribeOn(MainScheduler.instance)
            .subscribe(onSuccess: {url in
                let request = URLRequest(url: url)
                self.webview.load(request)
            }, onError: {error in
                
            }).disposed(by: disposeBag)
    }
}
