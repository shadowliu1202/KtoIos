import Foundation

internal class Util {
  public static func dispatchToMainThread(action: @escaping () -> Void) {
    DispatchQueue.main.async(execute: action)
  }
}
