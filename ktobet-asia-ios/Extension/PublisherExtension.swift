import Combine
import Foundation

extension Publisher where Failure == Error {
  func redirectErrors(to viewModel: ErrorCollectable) -> AnyPublisher<Output, Never> {
    self.catch { [weak viewModel] in
      viewModel?.collectError($0)
      return Empty(completeImmediately: true, outputType: Output.self, failureType: Never.self)
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
