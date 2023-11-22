import Combine
import Foundation
import sharedbu

// MARK: - RxKotlin to Combine
extension AnyPublisher where Output: AnyObject, Failure == Swift.Error {
  static func from(_ observable: ObservableWrapper<Output>) -> AnyPublisher<Output, Swift.Error> {
    ObservableWrapperPublisher(upstream: observable).eraseToAnyPublisher()
  }
  
  static func from(_ single: SingleWrapper<Output>) -> AnyPublisher<Output, Swift.Error> {
    SingleWrapperPublisher(upstream: single).eraseToAnyPublisher()
  }
}

extension AnyPublisher where Output == Void, Failure == Swift.Error {
  static func from(_ completable: CompletableWrapper) -> AnyPublisher<Void, Error> {
    CompletableWrapperPublisher(upstream: completable).eraseToAnyPublisher()
  }
}

// MARK: - Combine with Error to Async/Await
extension AnyPublisher where Output: Any, Failure: Error {
  var value: Output? {
    get async throws {
      var cancellable: AnyCancellable?
      var finishedWithoutValue = true
      return try await withTaskCancellationHandler(
        operation: {
          try await withCheckedThrowingContinuation { continuation in
            cancellable = first()
              .sink(
                receiveCompletion: {
                  switch $0 {
                  case .finished:
                    if finishedWithoutValue {
                      continuation.resume(returning: nil)
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
        },
        onCancel: { [cancellable] in
          cancellable?.cancel()
        })
    }
  }
  
  @available(*, deprecated, message: "Use `value`")
  func waitFirst() async throws -> Output? {
    var cancellable: AnyCancellable?
    var finishedWithoutValue = true
    return try await withTaskCancellationHandler(
      operation: {
        try await withCheckedThrowingContinuation { continuation in
          cancellable = first()
            .sink(
              receiveCompletion: {
                switch $0 {
                case .finished:
                  if finishedWithoutValue {
                    continuation.resume(returning: nil)
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
      },
      onCancel: { [cancellable] in
        cancellable?.cancel()
      })
  }
}

extension AnyPublisher where Output == Never, Failure: Error {
  @available(*, deprecated, message: "Use `value`")
  func wait() async throws {
    var cancellable: AnyCancellable?
    return try await withTaskCancellationHandler(
      operation: {
        try await withCheckedThrowingContinuation { continuation in
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
      },
      onCancel: { [cancellable] in
        cancellable?.cancel()
      })
  }
}

// MARK: - Combine without Error to Async/Await
extension AnyPublisher where Output: Any, Failure == Never {
  var valueWithoutError: Output? {
    get async {
      var cancellable: AnyCancellable?
      var finishedWithoutValue = true
      return await withTaskCancellationHandler(
        operation: {
          await withCheckedContinuation { continuation in
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
        },
        onCancel: { [cancellable] in
          cancellable?.cancel()
        })
    }
  }
  
  @available(*, deprecated, message: "Use `value`")
  func waitFirst() async -> Output? {
    var cancellable: AnyCancellable?
    var finishedWithoutValue = true
    return await withTaskCancellationHandler(
      operation: {
        await withCheckedContinuation { continuation in
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
      },
      onCancel: { [cancellable] in
        cancellable?.cancel()
      })
  }
}

extension AnyPublisher where Output == Never, Failure == Never {
  @available(*, deprecated, message: "Use `value`")
  func wait() async {
    var cancellable: AnyCancellable?
    return await withTaskCancellationHandler(
      operation: {
        await withCheckedContinuation { continuation in
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
      },
      onCancel: { [cancellable] in
        cancellable?.cancel()
      })
  }
}
