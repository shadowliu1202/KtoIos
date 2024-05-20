import Foundation
import Swinject
import SwinjectAutoregistration

public let Injectable = Injection.shared.container

@propertyWrapper
struct Injected<Dependency> {
    private var _wrappedValue: Dependency

    var wrappedValue: Dependency {
        get { _wrappedValue }
        set { _wrappedValue = newValue }
    }

    init() {
        _wrappedValue = Injectable ~> Dependency.self
    }

    init(name: String) {
        _wrappedValue = Injectable ~> (Dependency.self, name: name)
    }
}

extension ObjectScope {
    static let locale = ObjectScope(storageFactory: PermanentStorage.init)
}

extension Resolver {
    @available(*, deprecated) // replace with ~> operator or @Injected
    func resolveWrapper<T>(_ type: T.Type, name: String? = nil) -> T {
        guard let object = resolve(type, name: name)
        else {
            fatalError("\(T.self) init error")
        }
        return object
    }
}
