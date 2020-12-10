//
//  TestRepository.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/10.
//

import Foundation
import RxSwift
import SwiftyJSON


protocol GameInfoRepository {
    func getGameUrl()->Single<URL>
}

class GameInfoRepositoryImpl : GameInfoRepository{
    
    private var httpClient : HttpClient!
    private var apiGame : GameApi!
    private var unknownError = NSError.init(domain: "unknown error", code: 99999, userInfo: ["":""])
    private var disposeBag = DisposeBag()
    
    init(_ apiGame : GameApi, _ httpClient : HttpClient) {
        self.apiGame = apiGame
        self.httpClient = httpClient
    }
    
    func getGameUrl()->Single<URL>{
        return apiGame.getGameUrl()
    }
}

