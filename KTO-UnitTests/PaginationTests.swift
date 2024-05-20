import XCTest

@testable import ktobet_asia_ios_qat

final class PaginationTests: XCTestCase {
    func test_whenRefreshTriggerOnNext_thenElementsAreCorrectlyUpdated() {
        let sut = Pagination<Int>(
            startIndex: 1,
            offset: 1,
            observable: { currentIndex in
                .just([currentIndex])
            })

        sut.refreshTrigger.onNext(())

        let expect = [1]
        let actual = sut.elements.value

        XCTAssertEqual(expect, actual)
    }

    func testPageTypeAPI() {
        let sut = Pagination<Int>(
            startIndex: 1,
            offset: 1,
            observable: { currentIndex in
                .just([currentIndex])
            })

        sut.refreshTrigger.onNext(())
        sut.loadNextPageTrigger.onNext(())
        sut.loadNextPageTrigger.onNext(())
        sut.refreshTrigger.onNext(())

        let expect = [1, 2, 3]
        let actual = sut.elements.value

        XCTAssertEqual(expect, actual)
    }

    func testOffsetTypeAPI() {
        let sut = Pagination<Int>(
            startIndex: 0,
            offset: 20,
            observable: { currentIndex in
                .just([currentIndex])
            })

        sut.refreshTrigger.onNext(())
        sut.loadNextPageTrigger.onNext(())
        sut.loadNextPageTrigger.onNext(())
        sut.loadNextPageTrigger.onNext(())
        sut.refreshTrigger.onNext(())

        let expect = [0, 20, 40, 60]
        let actual = sut.elements.value

        XCTAssertEqual(expect, actual)
    }

    func test_whenIsLoading_thenElementsAreCorrectlyUpdated() {
        let sut = Pagination<Int>(
            startIndex: 1,
            offset: 1,
            observable: { currentIndex in
                .just([currentIndex])
            })

        sut.refreshTrigger.onNext(())
        sut.loadNextPageTrigger.onNext(())

        sut.loading.accept(true)

        sut.loadNextPageTrigger.onNext(())
        sut.refreshTrigger.onNext(())

        let expect = [1, 2]
        let actual = sut.elements.value

        XCTAssertEqual(expect, actual)
    }
}
