import Combine
import Foundation
import SharedBu

class ObservableWrapperPublisher<T, Upstream: ObservableWrapper<T>>: Publisher where T: AnyObject {
  typealias Output = T
  typealias Failure = Swift.Error

  private let upstream: Upstream

  init(upstream: Upstream) {
    self.upstream = upstream
  }

  func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
    subscriber.receive(subscription: ObservableWrapperSubscription(upstream: upstream, downstream: subscriber))
  }
}

class ObservableWrapperSubscription<T, Upstream: ObservableWrapper<T>, Downstream: Subscriber>: Combine.Subscription
  where T: AnyObject, Downstream.Input == T, Downstream.Failure == Swift.Error
{
  private var disposable: SharedBu.Disposable?
  private let buffer: DemandBuffer<Downstream>

  init(
    upstream: Upstream,
    downstream: Downstream)
  {
    buffer = DemandBuffer(subscriber: downstream)
    disposable = upstream.subscribe(
      isThreadLocal: false,
      onError: { [buffer] in buffer.complete(completion: .failure($0)) },
      onComplete: { [buffer] in buffer.complete(completion: .finished) },
      onNext: { [buffer] in _ = buffer.buffer(value: $0) })
  }
  
  func request(_ demand: Subscribers.Demand) {
    _ = buffer.demand(demand)
  }
  
  func cancel() {
    disposable?.dispose()
    disposable = nil
  }
}
