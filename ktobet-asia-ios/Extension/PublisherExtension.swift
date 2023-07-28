import Combine
import Foundation

extension Publisher where Failure == Error {
  func redirectErrors(to subject: PassthroughSubject<Error, Never>) -> AnyPublisher<Output, Never> {
    self.catch { [weak subject] error in
      subject?.send(error)
      return Empty(completeImmediately: false, outputType: Output.self, failureType: Never.self)
    }
    .eraseToAnyPublisher()
  }
}

extension Publisher where Failure == Never {
  func assignOptional(to published: inout Published<Self.Output?>.Publisher) {
    self.map { Optional($0) }
      .assign(to: &published)
  }
}
