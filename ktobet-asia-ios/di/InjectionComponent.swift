import Foundation
import Swinject

public let Injectable = Injection.shared.container

@propertyWrapper
struct Injected<Dependency> {
    private var _wrappedValue: Dependency
    
    var wrappedValue: Dependency {
        get { _wrappedValue }
        set { _wrappedValue = newValue }
    }
    
    init() {
        _wrappedValue = Injectable.resolveWrapper(Dependency.self)
    }
    
    init(name: String) {
        _wrappedValue = Injectable.resolveWrapper(Dependency.self, name: name)
    }
}

extension ObjectScope {
    static let application = ObjectScope(storageFactory: PermanentStorage.init)
    static let locale = ObjectScope(storageFactory: PermanentStorage.init)
    static let landing = ObjectScope(storageFactory: PermanentStorage.init)
    static let depositFlow = ObjectScope(storageFactory: PermanentStorage.init)
}

extension Resolver {
    func resolveWrapper<T>(_ type: T.Type, name: String? = nil) -> T {
        guard let object = resolve(T.self, name: name)
        else {
            fatalError("\(T.self) init error")
        }
        return object
    }
}

