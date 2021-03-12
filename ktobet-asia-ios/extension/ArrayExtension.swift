import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        if index < 0 || index > count - 1{
            return nil
        } else {
            return self[index]
        }
    }
}
