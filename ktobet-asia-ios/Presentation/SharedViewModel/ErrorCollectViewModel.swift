import Combine
import Foundation

protocol ErrorCollectable {
  var errorsSubject: PassthroughSubject<Error, Never> { get }
  
  func errors() -> AnyPublisher<Error, Never>
}

extension ErrorCollectable {
  func errors() -> AnyPublisher<Error, Never> {
    Empty().eraseToAnyPublisher()
  }
}

class ErrorCollectViewModel: ErrorCollectable {
  let errorsSubject = PassthroughSubject<Error, Never>()
  
  func errors() -> AnyPublisher<Error, Never> {
    errorsSubject
      .throttle(for: .milliseconds(1500), scheduler: DispatchQueue.main, latest: false)
      .eraseToAnyPublisher()
  }
}
