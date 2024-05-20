import Combine
import Foundation
import sharedbu

class SubscriptionManager {
    var cancellables = Set<AnyCancellable>()
}

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
            let manager = SubscriptionManager()
            var finishedWithoutValue = true
            return try await withTaskCancellationHandler(
                operation: {
                    guard !Task.isCancelled else { return nil }
          
                    return try await withCheckedThrowingContinuation { continuation in
                        first()
                            .handleEvents(receiveCancel: {
                                continuation.resume(returning: nil)
                            })
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
                
                                    manager.cancellables.removeAll()
                                },
                                receiveValue: {
                                    finishedWithoutValue = false
                                    continuation.resume(returning: $0)
                                })
                            .store(in: &manager.cancellables)
                    }
                },
                onCancel: {
                    manager.cancellables.removeAll()
                })
        }
    }
}

// MARK: - Combine without Error to Async/Await
extension AnyPublisher where Output: Any, Failure == Never {
    var valueWithoutError: Output? {
        get async {
            let manager = SubscriptionManager()
            var finishedWithoutValue = true
            return await withTaskCancellationHandler(
                operation: {
                    guard !Task.isCancelled else { return nil }
          
                    return await withCheckedContinuation { continuation in
                        first()
                            .handleEvents(receiveCancel: {
                                continuation.resume(returning: nil)
                            })
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

                                    manager.cancellables.removeAll()
                                },
                                receiveValue: {
                                    finishedWithoutValue = false
                                    continuation.resume(returning: $0)
                                })
                            .store(in: &manager.cancellables)
                    }
                },
                onCancel: {
                    manager.cancellables.removeAll()
                })
        }
    }
}
