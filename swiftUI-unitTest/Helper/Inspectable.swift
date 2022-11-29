import XCTest
import SwiftUI
import ViewInspector
@testable import ktobet_asia_ios_qat

protocol UITestable: Inspectable where Self: View {
    var inspection: Inspection<Self> { get }
}

extension PageContainer: Inspectable {}
extension SwiftUIInputText: Inspectable {}
extension UIKitTextField: Inspectable {}
extension LocalizeFont: Inspectable {}
extension Separator: Inspectable {}
extension LimitSpacer: Inspectable {}
