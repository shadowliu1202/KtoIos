import Combine
import Foundation

protocol ErrorCollectable: AnyObject {
    func collectError(_ error: Error)
    func errors() -> AnyPublisher<Error, Never>
}

extension ErrorCollectable {
    func errors() -> AnyPublisher<Error, Never> {
        Empty().eraseToAnyPublisher()
    }
}

class ErrorCollectViewModel: ErrorCollectable {
    private let errorsSubject = PassthroughSubject<Error, Never>()
  
    func collectError(_ error: Error) {
        errorsSubject.send(error)
    }
  
    func errors() -> AnyPublisher<Error, Never> {
        errorsSubject
            .receive(on: DispatchQueue.main)
            .throttle(for: .milliseconds(1500), scheduler: DispatchQueue.main, latest: false)
            .eraseToAnyPublisher()
    }
}
