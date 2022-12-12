import XCTest
import SwiftUI
import ViewInspector

@testable import ktobet_asia_ios_qat

protocol Inspecting: Inspectable, View {
    var inspection: Inspection<Self> { get }
}

extension PageContainer: Inspectable { }
extension SwiftUIInputText: Inspectable { }
extension SwiftUIDropDownText: Inspectable { }
extension UIKitTextField: Inspectable { }
extension LocalizeFont: Inspectable { }
extension Separator: Inspectable { }
extension LimitSpacer: Inspectable { }
extension FunctionalButton: Inspectable { }
