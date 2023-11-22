import Combine
import Foundation
import sharedbu

class CompletableWrapperPublisher<Upstream: CompletableWrapper>: Publisher {
  typealias Output = Void
  typealias Failure = Swift.Error

  private let upstream: Upstream

  init(upstream: Upstream) {
    self.upstream = upstream
  }

  func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
    subscriber.receive(subscription: CompletableWrapperSubscription(upstream: upstream, downstream: subscriber))
  }
}

class CompletableWrapperSubscription<Upstream: CompletableWrapper, Downstream: Subscriber>: Combine.Subscription
  where Downstream.Input == Void, Downstream.Failure == Swift.Error
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
      onComplete: { [buffer] in
        _ = buffer.buffer(value: ())
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
