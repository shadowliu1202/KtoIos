import Mockingbird
import RxSwift
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class KtoURLTests: XCTestCase {
  func stubRequest(name: String?, delay: Int) -> Single<String?> {
    .just(name)
      .delay(.seconds(delay), scheduler: MainScheduler())
  }

  func test_Checking4Host_WhenAIsFastest_ReturnAHost_KTO_TC_101() {
    let stubRequests = ["A": 1, "B": 3, "C": 5, "D": 7]
      .map {
        stubRequest(name: $0.key, delay: $0.value).asObservable()
      }

    let sut = PortalURL()

    let actual = sut.mergeRequestsAndBlocking(
      stubRequests,
      default: "")

    XCTAssertEqual(actual, "A")
  }

  func test_Checking4Host_WhenTimeOutAndAIsDefault_ReturnAHost() {
    let stubRequests = ["A": 11, "B": 13, "C": 15, "D": 17]
      .map {
        stubRequest(name: $0.key, delay: $0.value).asObservable()
      }

    let sut = PortalURL()

    let actual = sut.mergeRequestsAndBlocking(
      stubRequests,
      default: "A")

    XCTAssertEqual(actual, "A")
  }

  func test_Checking4Host_WhenAFailedButBIsFastest_ReturnBHost() {
    let stubRequests = [nil: 0, "B": 3, "C": 5, "D": 7]
      .map {
        stubRequest(name: $0.key, delay: $0.value).asObservable()
      }

    let sut = PortalURL()

    let actual = sut.mergeRequestsAndBlocking(
      stubRequests,
      default: "A")

    XCTAssertEqual(actual, "B")
  }
}
