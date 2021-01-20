//
//  CountDownTimer.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2021/1/7.
//

import Foundation
import RxSwift
import RxCocoa


class KTOTimer{
    
    var finishTime : TimeInterval = 0
    var timer : Timer?
    var index = 0
    
    deinit {
        stop()
    }
    
    func countDown(timeInterval : TimeInterval,
                   duration : TimeInterval,
                   block: ((_ index: Int, _ countDownSeconds: Int, _ finish: Bool)->())?){
        stop()
        if timeInterval <= 0 || duration <= 0 { return }
        if timeInterval > duration { return }
        finishTime = Date().timeIntervalSince1970 + duration
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { (t) in
            self.index += 1
            var countDownSeconds = Int(ceil(self.finishTime - Date().timeIntervalSince1970))
            if countDownSeconds <= 0 { countDownSeconds = 0}
            block?(self.index, countDownSeconds, countDownSeconds == 0)
            if countDownSeconds == 0 {
                self.stop()
            }
        })
        timer?.fire()
    }
    
    func countDown(timeInterval : TimeInterval,
                   endTime : Date,
                   block: ((_ index: Int, _ countDownSeconds: Int, _ finish: Bool)->())?){
        stop()
        if timeInterval <= 0 {
            return
            
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { (t) in
            self.index += 1
            var countDownSeconds = Int(ceil(endTime.timeIntervalSince1970 - Date().timeIntervalSince1970))
            if countDownSeconds <= 0 {
                countDownSeconds = 0
            }
            
            block?(self.index, countDownSeconds, countDownSeconds == 0)
            if countDownSeconds == 0 {
                self.stop()
            }
        })
        timer?.fire()
    }
    
    func repeate(timeInterval : TimeInterval, block : ((_ index : Int)->())?){
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { (t) in
            self.index += 1
            block?(self.index)
        })
        timer?.fire()
    }
    
    func stop(){
        timer?.invalidate()
        timer = nil
        index = 0
        finishTime = 0
    }
}
