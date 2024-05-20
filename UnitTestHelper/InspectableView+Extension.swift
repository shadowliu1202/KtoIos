import SwiftUI
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

extension Inspection: InspectionEmissary { }

extension InspectableView where View: SingleViewContent {
    func localizedText() throws
        -> InspectableView<ViewType.Text>
    {
        try view(LocalizeFont<Text>.self)
            .find(ViewType.Text.self)
    }
}

extension InspectableView where View: MultipleViewContent {
    func localizedText(_ index: Int) throws
        -> InspectableView<ViewType.Text>
    {
        try view(LocalizeFont<Text>.self, index)
            .find(ViewType.Text.self)
    }
}

extension InspectableView {
    func isExist(viewWithId id: String) -> Bool {
        do {
            _ = try self.find(viewWithId: id)
            return true
        }
        catch {
            return false
        }
    }

    func isExistByVisibility(viewWithId id: String) throws -> Bool {
        let view = try self.find(viewWithId: id)
            .modifier(VisibilityModifier.self)

        do {
            _ = try view.viewModifierContent()
            return true
        }
        catch {
            return false
        }
    }

    func isExistByLocale(viewWithId id: String) throws -> Bool {
        let view = try self.find(viewWithId: id)
            .modifier(VisibleLocaleModifier.self)

        do {
            _ = try view.viewModifierContent()
            return true
        }
        catch {
            return false
        }
    }
  
    func isAsyncButtonDisable(viewWithId id: String) throws -> Bool {
        try find(viewWithId: id)
            .find(viewWithId: "asyncButton")
            .button()
            .isDisabled()
    }
}
