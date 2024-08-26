import Combine
import Mockingbird
import RxSwift
import sharedbu
import SwiftUI
import XCTest

@testable import ktobet_asia_ios

final class AnyPublisherExtensionTests: XCTestCase {
    class TestClass {
        let order: Int
    
        init(order: Int) {
            self.order = order
        }
    }

    // MARK: - ObservableWrapper
    func test_ObservableWrapperWithoutError() {
        let expectation = expectation(description: "")
    
        var values = [Int]()
        var completeWithoutFailure: Bool?
    
        let observableWrapper = Observable<TestClass>
            .create { observer in
                observer.onNext(TestClass(order: 1))
                observer.onNext(TestClass(order: 2))
                observer.onNext(TestClass(order: 3))
                observer.onCompleted()
                return Disposables.create()
            }
            .do(onDispose: { expectation.fulfill() })
            .asWrapper()
        
        _ = AnyPublisher.from(observableWrapper)
            .sink(
                receiveCompletion: {
                    switch $0 {
                    case .finished:
                        completeWithoutFailure = true
                    case .failure:
                        completeWithoutFailure = false
                    }
                },
                receiveValue: {
                    values.append($0.order)
                })
    
        waitForExpectations(timeout: 10)
        
        XCTAssertEqual([1, 2, 3], values)
        XCTAssertTrue(completeWithoutFailure!)
    }
  
    func test_ObservableWrapperWithError() {
        let expectation = expectation(description: "")
    
        var values = [Int]()
        var completeWithoutFailure: Bool?
    
        let observableWrapper = Observable<TestClass>
            .create { observer in
                observer.onNext(TestClass(order: 1))
                observer.onNext(TestClass(order: 2))
                observer.onError(KTOError.EmptyData)
                observer.onNext(TestClass(order: 3))
                return Disposables.create()
            }
            .do(onDispose: { expectation.fulfill() })
            .asWrapper()
        
        _ = AnyPublisher.from(observableWrapper)
            .sink(
                receiveCompletion: {
                    switch $0 {
                    case .finished:
                        completeWithoutFailure = true
                    case .failure:
                        completeWithoutFailure = false
                    }
                },
                receiveValue: {
                    values.append($0.order)
                })
    
        waitForExpectations(timeout: 10)
        
        XCTAssertEqual([1, 2], values)
        XCTAssertFalse(completeWithoutFailure!)
    }
  
    // MARK: - SingleWrapper
    func test_SingleWrapperWithoutError() {
        let expectation = expectation(description: "")

        var values = [Int]()
        var completeWithoutFailure: Bool?
    
        let singleWrapper: SingleWrapper<TestClass> = Single<TestClass>
            .just(TestClass(order: 1))
            .do(onDispose: { expectation.fulfill() })
            .asWrapper()
        
        _ = AnyPublisher.from(singleWrapper)
            .sink(
                receiveCompletion: {
                    switch $0 {
                    case .finished:
                        completeWithoutFailure = true
                    case .failure:
                        completeWithoutFailure = false
                    }
                },
                receiveValue: {
                    values.append($0.order)
                })
    
        waitForExpectations(timeout: 10)

        XCTAssertEqual([1], values)
        XCTAssertTrue(completeWithoutFailure!)
    }
  
    func test_SingleWrapperWithError() {
        let expectation = expectation(description: "")

        var values = [Int]()
        var completeWithoutFailure: Bool?
    
        let singleWrapper: SingleWrapper<TestClass> = Single<TestClass>
            .error(KTOError.EmptyData)
            .do(onDispose: { expectation.fulfill() })
            .asWrapper()
        
        _ = AnyPublisher.from(singleWrapper)
            .sink(
                receiveCompletion: {
                    switch $0 {
                    case .finished:
                        completeWithoutFailure = true
                    case .failure:
                        completeWithoutFailure = false
                    }
                },
                receiveValue: {
                    values.append($0.order)
                })
    
        waitForExpectations(timeout: 10)

        XCTAssertEqual([], values)
        XCTAssertFalse(completeWithoutFailure!)
    }
  
    // MARK: - CompletableWrapper
    func test_CompletableWrapperWithoutError() {
        let expectation = expectation(description: "")

        var values = [Int]()
        var completeWithoutFailure: Bool?
    
        let observable = Observable<TestClass>
            .create { observer in
                observer.onNext(TestClass(order: 1))
                observer.onNext(TestClass(order: 2))
                observer.onNext(TestClass(order: 3))
                observer.onCompleted()
                return Disposables.create()
            }
            .do(onDispose: { expectation.fulfill() })
    
        let completableWrapper = CompletableWrapper(inner: CompletableByEmitterKt.completable(onSubscribe: { emitter in
            let swiftDisposable = observable
                .subscribe(
                    onError: { emitter.onError(error: KotlinThrowable.wrapError($0)) },
                    onCompleted: { emitter.onComplete() })

            emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
        }))
        
        _ = AnyPublisher.from(completableWrapper)
            .sink(
                receiveCompletion: {
                    switch $0 {
                    case .finished:
                        completeWithoutFailure = true
                    case .failure:
                        completeWithoutFailure = false
                    }
                },
                receiveValue: { _ in })
    
        waitForExpectations(timeout: 10)

        XCTAssertEqual([], values)
        XCTAssertTrue(completeWithoutFailure!)
    }
  
    func test_CompletableWrapperWithError() {
        let expectation = expectation(description: "")

        var values = [Int]()
        var completeWithoutFailure: Bool?
    
        let observable = Observable<TestClass>
            .create { observer in
                observer.onNext(TestClass(order: 1))
                observer.onNext(TestClass(order: 2))
                observer.onError(KTOError.EmptyData)
                observer.onNext(TestClass(order: 3))
                return Disposables.create()
            }
            .do(onDispose: { expectation.fulfill() })
    
        let completableWrapper = CompletableWrapper(inner: CompletableByEmitterKt.completable(onSubscribe: { emitter in
            let swiftDisposable = observable
                .subscribe(
                    onError: { emitter.onError(error: KotlinThrowable.wrapError($0)) },
                    onCompleted: { emitter.onComplete() })

            emitter.setDisposable(disposable: DisposableWrapper(disposable: swiftDisposable))
        }))
        
        _ = AnyPublisher.from(completableWrapper)
            .sink(
                receiveCompletion: {
                    switch $0 {
                    case .finished:
                        completeWithoutFailure = true
                    case .failure:
                        completeWithoutFailure = false
                    }
                },
                receiveValue: { _ in })
    
        waitForExpectations(timeout: 10)

        XCTAssertEqual([], values)
        XCTAssertFalse(completeWithoutFailure!)
    }
  
    // MARK: - Async/Await
    // Throwable
    func test_ThrowableAnyObjectPublisherWithoutError() async {
        let publisher = Just(TestClass(order: 1)).setFailureType(to: Error.self).eraseToAnyPublisher()
    
        var values = [Int]()
        var completeWithoutFailure: Bool?
    
        do {
            try await values.append(publisher.value!.order)
            completeWithoutFailure = true
        }
        catch {
            completeWithoutFailure = false
        }
    
        XCTAssertEqual([1], values)
        XCTAssertTrue(completeWithoutFailure!)
    }
  
    func test_ThrowableAnyObjectPublisherWithError() async {
        let publisher = Fail(outputType: TestClass.self, failure: KTOError.EmptyData).eraseToAnyPublisher()
    
        var values = [Int]()
        var completeWithoutFailure: Bool?
    
        do {
            if let order = try await publisher.value?.order {
                values.append(order)
            }
      
            completeWithoutFailure = true
        }
        catch {
            completeWithoutFailure = false
        }
    
        XCTAssertEqual([], values)
        XCTAssertFalse(completeWithoutFailure!)
    }
  
    func test_ThrowableVoidPublisherWithoutError() async {
        let publisher = Empty(completeImmediately: true, outputType: Void.self, failureType: Error.self).eraseToAnyPublisher()
    
        var completeWithoutFailure: Bool?
    
        do {
            try await publisher.value
            completeWithoutFailure = true
        }
        catch {
            completeWithoutFailure = false
        }
    
        XCTAssertTrue(completeWithoutFailure!)
    }
  
    func test_ThrowableVoidPublisherWithError() async {
        let publisher = Fail(outputType: Void.self, failure: KTOError.EmptyData).eraseToAnyPublisher()
    
        var completeWithoutFailure: Bool?
    
        do {
            try await publisher.value
            completeWithoutFailure = true
        }
        catch {
            completeWithoutFailure = false
        }
    
        XCTAssertFalse(completeWithoutFailure!)
    }
  
    @MainActor
    func test_givenThrowablePublisher_whenCnacelTask_thenReturnNil() async throws {
        let task: Task<Void, Error>!
        let subject = PassthroughSubject<String, Error>()
    
        var value: String? = ""
    
        task = Task {
            value = try await subject.eraseToAnyPublisher().value
        }
    
        task.cancel()
    
        try await task.value
        XCTAssertNil(value)
    }
  
    // NotThrowable
    func test_NonThrowableAnyObjectPublisher() async {
        let publisher: AnyPublisher<TestClass, Never> = Just(TestClass(order: 1)).setFailureType(to: Never.self)
            .eraseToAnyPublisher()
    
        var values = [Int]()
    
        if let testClass = await publisher.valueWithoutError {
            values.append(testClass.order)
        }
    
        XCTAssertEqual([1], values)
    }
  
    func test_NonThrowableVoidPublisher() async {
        let publisher = Empty(completeImmediately: true, outputType: Void.self, failureType: Never.self).eraseToAnyPublisher()
    
        var completeWithoutFailure: Bool?
    
        await publisher.valueWithoutError
        completeWithoutFailure = true
    
        XCTAssertTrue(completeWithoutFailure!)
    }
  
    @MainActor
    func test_givenNonThrowablePublisher_whenCnacelTask_thenReturnNil() async throws {
        let task: Task<Void, Never>!
        let subject = PassthroughSubject<String, Never>()
    
        var value: String? = ""
    
        task = Task {
            value = await subject.eraseToAnyPublisher().valueWithoutError
        }
    
        task.cancel()
    
        await task.value
        XCTAssertNil(value)
    }
}
