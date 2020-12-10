//
//  CustomServiceRepository.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2020/11/12.
//

import Foundation
import RxSwift
import SwiftyJSON


protocol CustomServiceRepository {
    func getToken()->Single<String>
    func serviceConnect(_ token : String)
    func serviceDisconnect()
}

class CustomServiceRepositoryImpl : CustomServiceRepository {
    
    private var socketConnect : HubConnection?
    private var apiCustomService : CustomServiceApi!
    private var httpClient : HttpClient!
    private var disposeBag = DisposeBag()
    
    init(_ apiCustomService : CustomServiceApi, _ httpClient : HttpClient) {
        self.apiCustomService = apiCustomService
        self.httpClient = httpClient
    }
    
    func getToken()->Single<String>{
        let checkAgain = apiCustomService.getSkillSurveyId()
            .flatMap { (surveyId) -> Single<String> in
                return self.apiCustomService.getSocketToken(surveyId)
            }.flatMap { (token) -> Single<String> in
                return self.apiCustomService.checkToken()
            }
        
        return apiCustomService.checkToken()
            .flatMap { (token) -> Single<String> in
                if token.count == 0 {
                    return checkAgain
                } else {
                    return Single.just(token)
                }
            }
    }
    
    func serviceConnect(_ token : String){
        
        socketConnect?.stop()
        socketConnect = nil
        
        if let url = URL(string: "wss://qat1.pivotsite.com/chat-ws?access_token=" + token){
            socketConnect = HubConnectionBuilder.init(url: url)
                .withJSONHubProtocol()
                .withHttpConnectionOptions(configureHttpOptions: { (option) in
                    option.skipNegotiation = true
//                    option.headers["Cookie"] = self.httpClient.getCookieContent()
                })
                .withLogging(minLogLevel: .debug)
                .withAutoReconnect()
                .withHubConnectionDelegate(delegate: self)
                .build()
            
            socketConnect!.start()
            /*
             socketConnect?.on(method: "Join", callback: {(identify : String) in
             print("Join : \(identify)")
             })
             
             socketConnect?.on(method: "Queued", callback: { (para : [String]) in
             print("Queued \(para)")
             })
             
             socketConnect?.on(method: "Dispatched", callback: { (para1 : String, para2 : String, para3 : String) in
             print("Dispatched \(para1), \(para2), \(para3)")
             })
             
             socketConnect?.on(method: "Message", callback: { (para1 : String, para2 : Int, para3 : String, para4 : String, para5 : String, para6 : Int, para7 : String, para8 : Int, para9 : String, para10 : Bool) in
             print("Message : \(para1), \(para2), \(para3), \(para4), \(para5), \(para6), \(para7), \(para8), \(para9), \(para10)")
             
             })
             */
        }
    }
    
    func serviceDisconnect(){
        socketConnect?.stop()
    }
}


extension CustomServiceRepositoryImpl : HubConnectionDelegate{
    func connectionDidOpen(hubConnection: HubConnection) {}
    func connectionDidFailToOpen(error: Error) {}
    func connectionDidClose(error: Error?) {}
}
