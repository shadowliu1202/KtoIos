import Combine
import Foundation
import sharedbu

extension AnyPublisher {
  enum AsyncError: Error {
    case finishedWithoutValue
  }
}

extension AnyPublisher where Output: AnyObject, Failure == Swift.Error {
  // MARK: - RxKotlin to Combine
  
  static func from(_ observable: ObservableWrapper<Output>) -> AnyPublisher<Output, Swift.Error> {
    ObservableWrapperPublisher(upstream: observable).eraseToAnyPublisher()
  }
  
  static func from(_ single: SingleWrapper<Output>) -> AnyPublisher<Output, Swift.Error> {
    SingleWrapperPublisher(upstream: single).eraseToAnyPublisher()
  }
}

extension AnyPublisher where Output == Never, Failure == Swift.Error {
  static func from(_ completable: CompletableWrapper) -> AnyPublisher<Never, Error> {
    CompletableWrapperPublisher(upstream: completable).eraseToAnyPublisher()
  }
}

// MARK: - Combine with Error to Async/Await
extension AnyPublisher where Output: AnyObject, Failure: Error {
  func waitFirst() async throws -> Output {
    try await withCheckedThrowingContinuation { continuation in
      var cancellable: AnyCancellable?
      var finishedWithoutValue = true
      
      cancellable = first()
        .sink(
          receiveCompletion: {
            switch $0 {
            case .finished:
              if finishedWithoutValue {
                continuation.resume(throwing: AsyncError.finishedWithoutValue)
              }
            case .failure(let error):
              continuation.resume(throwing: error)
            }
          
            cancellable?.cancel()
          },
          receiveValue: {
            finishedWithoutValue = false
            continuation.resume(returning: $0)
          })
    }
  }
}

extension AnyPublisher where Output == Never, Failure: Error {
  func wait() async throws {
    try await withCheckedThrowingContinuation { continuation in
      var cancellable: AnyCancellable?
      
      cancellable = first()
        .sink(
          receiveCompletion: {
            switch $0 {
            case .finished:
              continuation.resume()
            case .failure(let error):
              continuation.resume(throwing: error)
            }
          
            cancellable?.cancel()
          },
          receiveValue: { _ in })
    }
  }
}

// MARK: - Combine without Error to Async/Await
extension AnyPublisher where Output: Any, Failure == Never {
  func waitFirst() async -> Output? {
    await withCheckedContinuation { continuation in
      var cancellable: AnyCancellable?
      var finishedWithoutValue = true
      
      cancellable = first()
        .sink(
          receiveCompletion: {
            switch $0 {
            case .finished:
              if finishedWithoutValue {
                continuation.resume(returning: nil)
              }
            case .failure:
              fatalError("should not reach here.")
            }
          
            cancellable?.cancel()
          },
          receiveValue: {
            finishedWithoutValue = false
            continuation.resume(returning: $0)
          })
    }
  }
}

extension AnyPublisher where Output == Never, Failure == Never {
  func wait() async {
    await withCheckedContinuation { continuation in
      var cancellable: AnyCancellable?
      
      cancellable = first()
        .sink(
          receiveCompletion: {
            switch $0 {
            case .finished:
              continuation.resume()
            case .failure:
              fatalError("should not reach here.")
            }
          
            cancellable?.cancel()
          },
          receiveValue: { _ in })
    }
  }
}
