import RxCocoa
import RxSwift
import UIKit

class InputText: UIView {
  private var firstPosition = true
  private var isEditing = false
  private(set) var isEdited = false

  @IBInspectable public var disablePaste = false {
    didSet {
      textContent.disablePaste = disablePaste
    }
  }

  var editingChangedHandler: ((String) -> Void)?
  var shouldChangeCharactersIn: ((UITextField, NSRange, String) -> Bool)?
  var showPickerView: (() -> Void)?
  var hidePickerView: (() -> Void)?
  var maxLength = Int32.max
  var numberOnly = false

  private var labTitle = UILabel()
  private var labSubTitle = UILabel()
  var textContent = PasteableTextField()
  private var underline = UIView()
  var text: ControlProperty<String> {
    textContent.rx.text.orEmpty
  }

  // MARK: LIFE CYCLE
  override func awakeFromNib() {
    super.awakeFromNib()

    backgroundColor = UIColor.inputFocus
    labTitle.font = UIFont(name: "PingFangSC-Regular", size: 12)
    labTitle.textColor = UIColor.textPrimary
    labTitle.backgroundColor = .clear
    labTitle.numberOfLines = 0

    labSubTitle.font = UIFont(name: "PingFangSC-Regular", size: 16)
    labSubTitle.textColor = .white
    labSubTitle.backgroundColor = .clear

    textContent.textColor = .white
    textContent.backgroundColor = .clear
    textContent.font = UIFont(name: "PingFangSC-Regular", size: 16)
    textContent.borderStyle = .none
    textContent.delegate = self
    textContent.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
    textContent.addTarget(self, action: #selector(textFieldEditingDidEnd(_:)), for: .editingDidEnd)

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
    self.labSubTitle.frame = position.subTitle
    let changePosition = {
      self.labTitle.font = position.titleFont
      self.labTitle.frame = position.title
      self.textContent.frame = position.content
      self.underline.frame = CGRect(x: 0, y: self.bounds.maxY - 1, width: self.bounds.width, height: 1)
      self.backgroundColor = self.isEditing ? UIColor.inputFocus : UIColor.inputDefault
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
      let height: CGFloat = labTitle.text?.height(withConstrainedWidth: bounds.width - 30, font: titleFont) ?? 0
      let x: CGFloat = border
      let y = bounds.midY - height * 0.5
      return CGRect(x: x, y: y, width: bounds.width - 30, height: height)
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
      let height = labTitle.text?.height(withConstrainedWidth: bounds.width - 30, font: titleFont) ?? 0
      let x = border
      let y: CGFloat = 8
      return CGRect(x: x, y: y, width: bounds.width - 30, height: height)
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
  @IBInspectable public var titleLocalizeText: String? {
    get { labTitle.text }
    set { labTitle.text = newValue == nil ? nil : Localize.string(newValue!) }
  }

  func setTitle(_ title: String) {
    labTitle.text = title
  }

  func setContent(_ content: String) {
    textContent.text = content
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
  }

  func setIsEdited(_ isEdited: Bool) {
    self.textContent.isEnabled = isEdited
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
    editingChangedHandler?(textField.text?.halfWidth ?? "")
  }

  @objc
  private func textFieldEditingDidEnd(_ textField: UITextField) {
    textField.text = textField.text?.halfWidth
  }

  func setEditingChangedHandler(_ editingChangedHandler: ((String) -> Void)?) {
    self.editingChangedHandler = editingChangedHandler
  }
}

extension InputText: UITextFieldDelegate {
  func textFieldDidBeginEditing(_: UITextField) {
    isEditing = true
    isEdited = true
    adjustPosition()
    showPickerView?()
  }

  func textFieldDidEndEditing(_: UITextField) {
    isEditing = false
    adjustPosition()
    hidePickerView?()
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    if let shouldChangeCharactersIn = self.shouldChangeCharactersIn {
      return shouldChangeCharactersIn(textField, range, string)
    }
    else {
      let currentString: NSString = (textField.text ?? "") as NSString
      if numberOnly {
        return isNumber(replacementString: string) && isLessThanLimitLength(
          currentString: currentString,
          shouldChangeCharactersIn: range,
          replacementString: string)
      }
      else {
        return isLessThanLimitLength(
          currentString: currentString,
          shouldChangeCharactersIn: range,
          replacementString: string)
      }
    }
  }

  private func isNumber(replacementString string: String) -> Bool {
    let allowedCharacters = CharacterSet.decimalDigits
    let characterSet = CharacterSet(charactersIn: string)
    return allowedCharacters.isSuperset(of: characterSet)
  }

  private func isLessThanLimitLength(
    currentString: NSString,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String)
    -> Bool
  {
    let newString: NSString =
      currentString.replacingCharacters(in: range, with: string) as NSString
    return newString.length <= maxLength
  }
}

extension InputText {
  override func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
    if !textContent.isFirstResponder {
      textContent.becomeFirstResponder()
    }
  }
}
