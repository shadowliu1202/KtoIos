import Foundation
import SwiftUI

enum PublishEvent<T>: Equatable {
    static func == (_: PublishEvent, _: PublishEvent) -> Bool {
        return false
    }

    case error(Error)
    case event(T)
}

protocol EventConsumer {
    associatedtype CustomEvent
    var publisher: PublishEvent<CustomEvent>? { get }
    func consumed()
}

class ComposeObservableObject<T>: ObservableObject, EventConsumer {
    @Published var publisher: PublishEvent<T>? = nil
    func consumed() {
        publisher = nil
    }
}

extension View {
    func onConsume<Consumer: EventConsumer>(_ errorHandler: HandleError, _ consumer: Consumer, _ consume: @escaping (Consumer.CustomEvent) -> Void = { _ in }) -> some View {
        return onChange(of: consumer.publisher) { event in
            switch event {
            case let .error(err):
                errorHandler(error: err)
            case .none:
                break
            case let .some(.event(customEvent)):
                consume(customEvent)
            }
            consumer.consumed()
        }
    }
}
