import RxCocoa
import RxSwift
import UIKit

protocol InputConfirmPasswordDelegate {
  func shouldFocus(_ focus: Bool)
  func getFocus() -> Bool
}

class InputConfirmPassword: UIView {
  private var firstPosition = true
  private var isEditing = false
  private var editingChangedHandler: ((String) -> Void)?

  private var labTitle = UILabel()
  private var labSubTitle = UILabel()
  private var textContent = PasswordTextField()
  private var underline = UIView()
  var text: ControlProperty<String> {
    textContent.rx.text.orEmpty
  }

  var inputPassword: InputConfirmPasswordDelegate?
  var isFocus = false

  // MARK: LIFE CYCLE
  override func awakeFromNib() {
    super.awakeFromNib()

    backgroundColor = UIColor.inputFocus
    labTitle.font = UIFont(name: "PingFangSC-Regular", size: 12)
    labTitle.textColor = UIColor.textPrimary
    labTitle.backgroundColor = .clear

    labSubTitle.font = UIFont(name: "PingFangSC-Regular", size: 16)
    labSubTitle.textColor = .white
    labSubTitle.backgroundColor = .clear

    textContent.textColor = .white
    textContent.tintColor = .primaryDefault
    textContent.backgroundColor = .clear
    textContent.font = UIFont(name: "PingFangSC-Regular", size: 16)
    textContent.borderStyle = .none
    textContent.delegate = self
    textContent.isSecureTextEntry = true
    textContent.disableAutoFillOnIos16()
    textContent.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)

    underline.backgroundColor = UIColor.alert
    underline.isHidden = true

    addSubview(labTitle)
    addSubview(labSubTitle)
    addSubview(textContent)
    addSubview(underline)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    adjustPosition()
  }

  // MARK: POSITION
  func adjustPosition() {
    var position: (titleFont: UIFont, title: CGRect, subTitle: CGRect, content: CGRect)

    if !isEditing, textContent.text?.count == 0 {
      position = emptyPosition()
    }
    else {
      position = editedPosition()
    }

    self.textContent.frame = position.content
    let changePosition = {
      self.labTitle.font = position.titleFont
      self.labTitle.frame = position.title
      self.labSubTitle.frame = position.subTitle
      self.underline.frame = CGRect(x: 0, y: self.bounds.maxY - 2, width: self.bounds.width, height: 2)
      self.backgroundColor = self.getAllFocus() ? UIColor.inputFocus : UIColor.inputDefault
    }
    if firstPosition {
      changePosition()
      firstPosition = false
    }
    else {
      UIView.animate(withDuration: 0.2, animations: changePosition, completion: nil)
    }
  }

  private func emptyPosition() -> (titleFont: UIFont, title: CGRect, subTitle: CGRect, content: CGRect) {
    let titleFont = UIFont(name: "PingFangSC-Regular", size: 14)!
    let border: CGFloat = 15
    let title: CGRect = {
      let width: CGFloat = labTitle.text?.width(withConstrainedHeight: bounds.height, font: titleFont) ?? 0
      let height: CGFloat = labTitle.text?.height(withConstrainedWidth: width, font: titleFont) ?? 0
      let x: CGFloat = border
      let y = bounds.midY - height * 0.5
      return CGRect(x: x, y: y, width: width, height: height)
    }()
    let subTitle = CGRect.zero
    let content: CGRect = {
      let width: CGFloat = bounds.width - border * 2
      let height: CGFloat = bounds.height - border * 2
      let x: CGFloat = title.maxX + border
      let y: CGFloat = bounds.midY - height * 0.5
      return CGRect(x: x, y: y, width: width, height: height)
    }()
    return (titleFont, title, subTitle, content)
  }

  private func editedPosition() -> (titleFont: UIFont, title: CGRect, subTitle: CGRect, content: CGRect) {
    let titleFont = UIFont(name: "PingFangSC-Regular", size: 12)!
    let border: CGFloat = 15
    let title: CGRect = {
      let width = labTitle.text?.width(withConstrainedHeight: bounds.height, font: titleFont) ?? 0 + 2
      let height = labTitle.text?.height(withConstrainedWidth: width, font: titleFont) ?? 0
      let x = border
      let y: CGFloat = 8
      return CGRect(x: x, y: y, width: width, height: height)
    }()
    let subTitle: CGRect = {
      guard (labSubTitle.text ?? "").count > 0 else { return CGRect.zero }
      let height = bounds.height - title.maxY - 8 - 8
      let width = labSubTitle.text?.width(withConstrainedHeight: height, font: labSubTitle.font) ?? 0
      let x = border
      let y = title.maxY + 8
      return CGRect(x: x, y: y, width: width, height: height)
    }()
    let content: CGRect = {
      let width = bounds.width - subTitle.maxX - (subTitle.equalTo(CGRect.zero) ? 0 : 8) - border
      let height = bounds.height - title.maxY - 8 - 8
      let x = subTitle.equalTo(CGRect.zero) ? border : subTitle.maxX + 8
      let y = title.maxY + 8
      return CGRect(x: x, y: y, width: width, height: height)
    }()
    return (titleFont, title, subTitle, content)
  }

  // MARK: SETUP UI
  func setTitle(_ title: String) {
    labTitle.text = title
  }

  func setSubTitle(_ subTitle: String) {
    labSubTitle.text = subTitle
  }

  func setKeyboardType(_ keyboardType: UIKeyboardType) {
    textContent.keyboardType = keyboardType
  }

  func setCorner(topCorner: Bool, bottomCorner: Bool) {
    layer.masksToBounds = true
    layer.cornerRadius = 8
    if topCorner, bottomCorner {
      layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
    else if topCorner {
      layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    else if bottomCorner {
      layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    }
    else {
      layer.maskedCorners = []
    }
  }

  // MARK: PRESENT
  func showKeyboard() {
    textContent.becomeFirstResponder()
  }

  func showUnderline(_ show: Bool) {
    underline.isHidden = !show
  }

  // MARK: TEXT HANDLER
  @objc
  private func textFieldEditingChanged(_ textField: UITextField) {
    editingChangedHandler?(textField.text ?? "")
  }

  func setEditingChangedHandler(_ editingChangedHandler: ((String) -> Void)?) {
    self.editingChangedHandler = editingChangedHandler
  }

  func getAllFocus() -> Bool {
    self.isFocus || self.isEditing || (inputPassword?.getFocus() ?? false)
  }
}

extension InputConfirmPassword: UITextFieldDelegate {
  func textFieldShouldBeginEditing(_: UITextField) -> Bool {
    isEditing = true
    inputPassword?.shouldFocus(true)
    adjustPosition()
    return true
  }

  func textFieldDidEndEditing(_: UITextField) {
    isEditing = false
    inputPassword?.shouldFocus(false)
    adjustPosition()
  }
}

extension InputConfirmPassword {
  override func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
    if !textContent.isFirstResponder {
      textContent.becomeFirstResponder()
      isEditing = true
    }
  }
}

extension InputConfirmPassword: InputPasswordDelegate {
  func getFocus() -> Bool {
    isFocus || isEditing
  }

  func shouldFocus(_ focus: Bool) {
    isFocus = focus
    self.backgroundColor = {
      guard self.getAllFocus() else {
        return UIColor.inputDefault
      }
      return UIColor.inputFocus
    }()
  }

  func shouldHidePassword(_ hide: Bool) {
    textContent.isSecureTextEntry = hide
  }
}
