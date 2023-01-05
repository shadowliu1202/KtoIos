import XCTest
import SwiftUI
import ViewInspector

@testable import ktobet_asia_ios_qat

protocol Inspecting: View {
    var inspection: Inspection<Self> { get }
}
