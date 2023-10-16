import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class KotlinThrowableTests: XCTestCase {
  func testWrapErrorWithKotlinThrowable() {
    let expect = ApiException(message: "test", errorCode: "200")
    let actual = KotlinThrowable.wrapError(ApiException(message: "test", errorCode: "200")) as! ApiException
    
    XCTAssertTrue(expect.isEqual(actual))
  }
  
  func testWrapErrorWithSwiftError() {
    let expect = ErrorWrapper(wrapped: NSError(domain: "test", code: 200))
    let actual = KotlinThrowable.wrapError(NSError(domain: "test", code: 200)) as! ErrorWrapper
    
    XCTAssertTrue(expect.isEqual(actual))
  }
  
  func testUnwrapErrorWithKotlinThrowable() {
    let expect = ApiException(message: "test", errorCode: "200")
    let actual = ApiException(message: "test", errorCode: "200").unwrapToError() as! ApiException
    
    XCTAssertTrue(expect.isEqual(actual))
  }
  
  func testUnWrapErrorWithSwiftError() {
    let expect = NSError(domain: "test", code: 200)
    let actual = ErrorWrapper(wrapped: NSError(domain: "test", code: 200)).unwrapToError() as NSError
    
    XCTAssertEqual(expect, actual)
  }
}
