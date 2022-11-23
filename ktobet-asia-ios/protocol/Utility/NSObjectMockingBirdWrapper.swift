import Foundation

///  - Mockingbird mock generate script wont automatically add `override`.
///  - In order to solve the problem, need to add another initalize.
protocol NSObjectMockingbirdWrapper {
    init(_ ignoreThis: Void)
}
