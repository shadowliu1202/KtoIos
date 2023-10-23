import Combine
import Foundation
import UIKit

class TextFieldUndoManager: UndoManager {
  private let textSubject = PassthroughSubject<String, Never>()
  
  private weak var textField: UITextField?
  private var registerCompletion: ((_ currentText: String) -> Void)?
  private var undoCompletion: ((_ undoText: String) -> Void)?
  private var cancellables = Set<AnyCancellable>()
  
  init(textField: UITextField?) {
    self.textField = textField
    
    super.init()
    
    setupDebouncedRegisterUndo()
  }
  
  override private init() { }
  
  private func setupDebouncedRegisterUndo() {
    textSubject
      .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
      .sink(receiveValue: { [unowned self] in
        registerUndo(withTarget: self, selector: #selector(executeUndo), object: $0)
        registerCompletion?(textField?.text ?? "")
      })
      .store(in: &cancellables)
  }
  
  func registerUndo(
    _ text: String,
    registerCompletion: @escaping (_ currentText: String) -> Void,
    undoCompletion: @escaping (_ undoText: String) -> Void)
  {
    if self.registerCompletion == nil {
      self.registerCompletion = registerCompletion
    }
    
    if self.undoCompletion == nil {
      self.undoCompletion = undoCompletion
    }
    
    textSubject.send(text)
  }
  
  @objc
  private func executeUndo(_ undoText: String) {
    let currentText = textField?.text ?? ""
    registerUndo(withTarget: self, selector: #selector(executeUndo), object: currentText)
    undoCompletion?(undoText)
    textField?.text = undoText
  }
}
