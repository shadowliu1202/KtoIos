import Combine
import Foundation
import sharedbu

class SingleWrapperPublisher<T, Upstream: SingleWrapper<T>>: Publisher where T: AnyObject {
  typealias Output = T
  typealias Failure = Swift.Error

  private let upstream: Upstream

  init(upstream: Upstream) {
    self.upstream = upstream
  }

  func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
    subscriber.receive(subscription: SingleWrapperSubscription(upstream: upstream, downstream: subscriber))
  }
}

class SingleWrapperSubscription<T, Upstream: SingleWrapper<T>, Downstream: Subscriber>: Combine.Subscription
  where T: AnyObject, Downstream.Input == T, Downstream.Failure == Swift.Error
{
  private var disposable: sharedbu.Disposable?
  private let buffer: DemandBuffer<Downstream>

  init(
    upstream: Upstream,
    downstream: Downstream)
  {
    buffer = DemandBuffer(subscriber: downstream)
    disposable = upstream.subscribe(
      isThreadLocal: false,
      onError: { [buffer] in buffer.complete(completion: .failure($0)) },
      onSuccess: { [buffer] in
        _ = buffer.buffer(value: $0)
        buffer.complete(completion: .finished)
      })
  }
  
  func request(_ demand: Subscribers.Demand) {
    _ = buffer.demand(demand)
  }
  
  func cancel() {
    disposable?.dispose()
    disposable = nil
  }
}
