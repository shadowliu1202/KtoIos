import Foundation
import Swinject

public let Injectable = Injection.shared.container

@propertyWrapper
struct Injected<Dependency> {
    let wrappedValue: Dependency
    
    init() {
        wrappedValue = Injectable.resolveWrapper(Dependency.self)
    }
    
    init(name: String) {
        wrappedValue = Injectable.resolveWrapper(Dependency.self, name: name)
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

