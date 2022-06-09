//
//  CountDownTimer.swift
//  ktobet-asia-ios
//
//  Created by Partick Chen on 2021/1/7.
//

import Foundation
import RxSwift
import RxCocoa


class CountDownTimer {
    
    var finishTime : TimeInterval = 0
    var timer : Timer?
    var index = 0
    
    deinit {
        stop()
    }
    
    func isStart() -> Bool {
        timer?.isValid ?? false
    }
    
    func start(timeInterval : TimeInterval,
               duration : TimeInterval,
               block: ((_ index: Int, _ countDownSeconds: Int, _ finish: Bool)->())?){
        stop()
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
        RunLoop.main.add(timer!, forMode: .common)
        timer?.fire()
    }
    
    func start(timeInterval : TimeInterval,
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
        RunLoop.main.add(timer!, forMode: .common)
        timer?.fire()
    }
    
    func `repeat`(timeInterval : TimeInterval, block : ((_ index : Int)->())?){
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true, block: { (t) in
            self.index += 1
            block?(self.index)
        })
        RunLoop.main.add(timer!, forMode: .common)
        timer?.fire()
    }
    
    func stop(){
        timer?.invalidate()
        timer = nil
        index = 0
        finishTime = 0
    }
}
