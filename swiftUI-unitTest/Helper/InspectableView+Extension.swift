import XCTest
import SwiftUI
import ViewInspector

@testable import ktobet_asia_ios_qat

extension Inspection: InspectionEmissary {}

extension InspectableView {
    
    func findText() throws -> InspectableView<ViewType.Text> {
        try find(ViewType.Text.self)
    }
}
