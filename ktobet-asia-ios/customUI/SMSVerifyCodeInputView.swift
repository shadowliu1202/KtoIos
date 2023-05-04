import Foundation
import RxCocoa
import UIKit

class SMSVerifyCodeInputView: UIView {
  @IBOutlet private var btnStackView: UIStackView!
  @IBOutlet private var codeStackView: UIStackView!

  private var otpLength = 0
  private var codes: [UIView] = []
  private var btns: [UIButton] = []

  override func awakeFromNib() {
    super.awakeFromNib()
  }

  func setOtpMaxLength(otpLength: Int32) {
    self.otpLength = Int(otpLength)
    initialize(otpLength)
  }

  func getOtpCode() -> Observable<String> {
    let codesOb = codes
      .compactMap { view -> ControlProperty<String>? in
        guard let textField = view.subviews.first as? SMSCodeTextField
        else { return nil }

        return textField.rx.text.orEmpty
      }

    return Observable.combineLatest(codesOb).map { stringElement -> String in
      stringElement.reduce("") { $0 + $1 }
    }
  }

  private func initialize(_ otpLength: Int32) {
    for index in 0..<Int(otpLength) {
      let backgroundView = UIView()
      let code = SMSCodeTextField()
      let btn = UIButton()

      backgroundView.backgroundColor = .white.withAlphaComponent(0.15)
      backgroundView.cornerRadius = 6
      backgroundView.widthAnchor.constraint(equalToConstant: 40).isActive = true
      backgroundView.heightAnchor.constraint(equalToConstant: 40).isActive = true

      backgroundView.addSubview(code)

      code.myDelegate = self
      code.textContentType = .oneTimeCode
      code.keyboardType = .numberPad
      code.textAlignment = .left
      code.textColor = .white
      code.tintColor = .redF20000
      code.backgroundColor = .clear
      code.layer.cornerRadius = 6
      code.layer.masksToBounds = true
      code.tag = index
      code.font = UIFont(name: "PingFangSC-Semibold", size: 18)
      code.addTarget(self, action: #selector(textEditingChaged(_:)), for: .editingChanged)

      guard let codeSuperView = code.superview else { return }

      code.translatesAutoresizingMaskIntoConstraints = false
      code.leadingAnchor.constraint(equalTo: codeSuperView.leadingAnchor, constant: 14).isActive = true
      code.trailingAnchor.constraint(equalTo: codeSuperView.trailingAnchor).isActive = true
      code.topAnchor.constraint(equalTo: codeSuperView.topAnchor).isActive = true
      code.bottomAnchor.constraint(equalTo: codeSuperView.bottomAnchor).isActive = true

      btn.translatesAutoresizingMaskIntoConstraints = false
      btn.widthAnchor.constraint(equalToConstant: 40).isActive = true
      btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
      btn.addTarget(self, action: #selector(btnCodePressed(_:)), for: .touchUpInside)
      btn.tag = index
      codes.append(backgroundView)
      btns.append(btn)
      codeStackView.insertArrangedSubview(backgroundView, at: index)
      btnStackView.insertArrangedSubview(btn, at: index)
    }

    backgroundColor = .clear
  }

  @objc
  private func btnCodePressed(_ sender: UIButton) {
    guard let codeTextField = codes[sender.tag].subviews.first as? SMSCodeTextField
    else { return }

    codeTextField.becomeFirstResponder()
  }

  @objc
  private func textEditingChaged(_ sender: UITextField) {
    if let text = sender.text, text.count >= 1, text.count < otpLength {
      sender.text = {
        let index = text.index(text.endIndex, offsetBy: -1)
        return String(text[index])
      }()

      let index = sender.tag + 1 > otpLength - 1 ? otpLength - 1 : sender.tag + 1

      guard let codeTextField = codes[index].subviews.first as? SMSCodeTextField
      else { return }

      codeTextField.becomeFirstResponder()
    }
  }
}

extension SMSVerifyCodeInputView: SMSCodeTextFieldDelegate, UITextFieldDelegate {
  func textFieldDidDelete(_ sender: SMSCodeTextField) {
    if (sender.text?.count ?? 0) == 0 {
      let index = sender.tag - 1 < 0 ? 0 : sender.tag - 1

      guard let codeTextField = codes[index].subviews.first as? SMSCodeTextField
      else { return }

      codeTextField.becomeFirstResponder()
    }
  }
}
