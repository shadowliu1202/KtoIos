//
//  SMSVerifyCodeInputView.swift
//  ktobet-asia-ios
//
//  Created by Patrick.chen on 2021/1/15.
//

import Foundation
import UIKit
import RxCocoa


class SMSVerifyCodeInputView : UIView{
    
    var btn1 = UIButton()
    var btn2 = UIButton()
    var btn3 = UIButton()
    var btn4 = UIButton()
    var btn5 = UIButton()
    var btn6 = UIButton()
    var code1 = SMSCodeTextField()
    var code2 = SMSCodeTextField()
    var code3 = SMSCodeTextField()
    var code4 = SMSCodeTextField()
    var code5 = SMSCodeTextField()
    var code6 = SMSCodeTextField()

    override func awakeFromNib() {
        super.awakeFromNib()
        initialize()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let codes = [code1, code2, code3, code4, code5, code6]
        let btns = [btn1, btn2, btn3, btn4, btn5, btn6]
        let height = bounds.size.height
        let width = height
        let space : CGFloat = {
            let count = CGFloat(codes.count)
            guard bounds.size.width > width * count else { return 0 }
            return (bounds.size.width - width * count) / (count - 1)
        }()
        var startX = CGFloat(0)
        let y = CGFloat(0)
        for idx in 0...5{
            codes[idx].frame = CGRect(x: startX, y: y, width: width, height: height)
            btns[idx].frame = CGRect(x: startX, y: y, width: width, height: height)
            startX += space
            startX += width
        }
    }
    
    private func initialize(){
        let codes = [code1, code2, code3, code4, code5, code6]
        let btns = [btn1, btn2, btn3, btn4, btn5, btn6]
        for idx in 0...5{
            codes[idx].myDelegate = self
            codes[idx].textContentType = .oneTimeCode
            codes[idx].keyboardType = .numberPad
            codes[idx].textAlignment = .center
            codes[idx].textColor = .white
            codes[idx].backgroundColor = .white15
            codes[idx].layer.cornerRadius = 6
            codes[idx].layer.masksToBounds = true
            codes[idx].font = UIFont.init(name: "PingFangSC-Semibold", size: 18)
            codes[idx].addTarget(self, action: #selector(textEditingChaged(_:)), for: .editingChanged)
            btns[idx].addTarget(self, action: #selector(btnCodePressed(_:)), for: .touchUpInside)
            addSubview(codes[idx])
            addSubview(btns[idx])
        }
        backgroundColor = .clear
    }
    
    @objc private func btnCodePressed(_ sender : UIButton){
        switch sender {
        case btn1: code1.becomeFirstResponder()
        case btn2: code2.becomeFirstResponder()
        case btn3: code3.becomeFirstResponder()
        case btn4: code4.becomeFirstResponder()
        case btn5: code5.becomeFirstResponder()
        case btn6: code6.becomeFirstResponder()
        default: break
        }
    }
    
    @objc private func textEditingChaged(_ sender : UITextField){
        if let text = sender.text, text.count >= 1, text.count < 6 {
            sender.text = {
                let index = text.index(text.endIndex, offsetBy: -1)
                return String(text[index])
            }()
            switch sender {
            case code1: code2.becomeFirstResponder()
            case code2: code3.becomeFirstResponder()
            case code3: code4.becomeFirstResponder()
            case code4: code5.becomeFirstResponder()
            case code5: code6.becomeFirstResponder()
            case code6: code6.resignFirstResponder()
            default: break
            }
        }
    }
}


extension SMSVerifyCodeInputView : SMSCodeTextFieldDelegate, UITextFieldDelegate{
    func textFieldDidDelete(_ sender: SMSCodeTextField) {
        if (sender.text?.count ?? 0) == 0{
            switch sender {
            case code6: code5.becomeFirstResponder()
            case code5: code4.becomeFirstResponder()
            case code4: code3.becomeFirstResponder()
            case code3: code2.becomeFirstResponder()
            case code2: code1.becomeFirstResponder()
            default: break
            }
        }
    }
}
