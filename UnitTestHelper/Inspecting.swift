import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

protocol Inspecting: View {
    var inspection: Inspection<Self> { get }
}
