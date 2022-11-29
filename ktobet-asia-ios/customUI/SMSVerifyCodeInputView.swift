//
//  SMSVerifyCodeInputView.swift
//  ktobet-asia-ios
//
//  Created by Patrick.chen on 2021/1/15.
//

import Foundation
import UIKit
import RxCocoa


class SMSVerifyCodeInputView: UIView {
    @IBOutlet private var btnStackView: UIStackView!
    @IBOutlet private var codeStackView: UIStackView!

    private var otpLength = 0
    private var codes: [SMSCodeTextField] = []
    private var btns: [UIButton] = []

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setOtpMaxLength(otpLength: Int32) {
        self.otpLength = Int(otpLength)
        initialize(otpLength)
    }

    func getOtpCode() -> Observable<String> {
        let codesOb = codes.map { $0.rx.text.orEmpty }
        return Observable.combineLatest(codesOb).map { stringElement -> String in
            stringElement.reduce("") { $0 + $1 }
        }
    }

    private func initialize(_ otpLength: Int32) {
        for index in 0..<Int(otpLength) {
            let code = SMSCodeTextField()
            let btn = UIButton()
            code.myDelegate = self
            code.textContentType = .oneTimeCode
            code.keyboardType = .numberPad
            code.textAlignment = .center
            code.textColor = .white
            code.backgroundColor = .white.withAlphaComponent(0.15)
            code.layer.cornerRadius = 6
            code.layer.masksToBounds = true
            code.tag = index
            code.font = UIFont.init(name: "PingFangSC-Semibold", size: 18)
            code.addTarget(self, action: #selector(textEditingChaged(_:)), for: .editingChanged)
            code.translatesAutoresizingMaskIntoConstraints = false
            code.widthAnchor.constraint(equalToConstant: 40).isActive = true
            code.heightAnchor.constraint(equalToConstant: 40).isActive = true

            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: 40).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
            btn.addTarget(self, action: #selector(btnCodePressed(_:)), for: .touchUpInside)
            btn.tag = index
            codes.append(code)
            btns.append(btn)
            codeStackView.insertArrangedSubview(code, at: index)
            btnStackView.insertArrangedSubview(btn, at: index)
        }

        backgroundColor = .clear
    }

    @objc private func btnCodePressed(_ sender: UIButton) {
        codes[sender.tag].becomeFirstResponder()
    }

    @objc private func textEditingChaged(_ sender: UITextField) {
        if let text = sender.text, text.count >= 1, text.count < otpLength {
            sender.text = {
                let index = text.index(text.endIndex, offsetBy: -1)
                return String(text[index])
            }()

            let index = sender.tag + 1 > otpLength - 1 ? otpLength - 1: sender.tag + 1
            codes[index].becomeFirstResponder()
        }
    }
}


extension SMSVerifyCodeInputView: SMSCodeTextFieldDelegate, UITextFieldDelegate {
    func textFieldDidDelete(_ sender: SMSCodeTextField) {
        if (sender.text?.count ?? 0) == 0 {
            let index = sender.tag - 1 < 0 ? 0 : sender.tag - 1
            codes[index].becomeFirstResponder()
        }
    }
}
