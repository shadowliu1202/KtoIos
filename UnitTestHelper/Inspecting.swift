import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios

protocol Inspecting: View {
    var inspection: Inspection<Self> { get }
}
