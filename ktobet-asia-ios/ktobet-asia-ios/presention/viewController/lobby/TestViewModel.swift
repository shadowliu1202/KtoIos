//
//  TestViewModel.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/10.
//

import Foundation
import RxSwift


class TestViewModel {
    
    private var httpClient : HttpClient!
    private var gameRepo : GameInfoRepository!
    private var customServiceRepo : CustomServiceRepository!
    private var unknownError = NSError.init(domain: "unknown error", code: 99999, userInfo: ["":""])
    
    init(_ gameRepo : GameInfoRepository, _ customServiceRepo : CustomServiceRepository, _ httpClient : HttpClient) {
        self.gameRepo = gameRepo
        self.customServiceRepo = customServiceRepo
        self.httpClient = httpClient
    }
    
    func getCookies()->[HTTPCookie]{
        return []
//        return httpClient.getCookies()
    }
    
    func getGameUrl()->Single<URL>{
        return gameRepo.getGameUrl()
    }
    
    func getToken()->Single<String>{
        return customServiceRepo.getToken()
    }
    
    func customServiceConnect(_ token : String){
        customServiceRepo.serviceConnect(token)
    }
    
    func customServiceDisconnect(){
        customServiceRepo.serviceDisconnect()
    }
}
