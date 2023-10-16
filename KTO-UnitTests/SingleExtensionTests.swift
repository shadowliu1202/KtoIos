import RxBlocking
import sharedbu
import XCTest

@testable import ktobet_asia_ios_qat

final class SingleExtensionTests: XCBaseTestCase {
  func testTransformBoolToString() {
    let json =
      """
      {
        "statusCode": "",
        "errorMsg": "",
        "node": "a5402fa77ba4",
        "data": true
      }
      """

    let s: SingleWrapper<ResponseItem<NSString>> = Single
      .just(json)
      .asReaktiveResponseItem(transfrom: { (boolean: Bool) -> NSString in
        switch boolean {
        case true:
          return "Yes"
        case false:
          return "No"
        }
      })

    let expect = "Yes"
    let response: ResponseItem<NSString> = try! Single.from(s).toBlocking(timeout: 10).first()!
    let actual = response.data! as String

    XCTAssertEqual(expect, actual)
  }

  func testTransformBoolToKotlinBoolean() {
    let json =
      """
      {
        "statusCode": "",
        "errorMsg": "",
        "node": "a5402fa77ba4",
        "data": true
      }
      """

    let s: SingleWrapper<ResponseItem<KotlinBoolean>> = Single
      .just(json)
      .asReaktiveResponseItem(transfrom: { (bool: Bool) -> KotlinBoolean in
        KotlinBoolean(bool: bool)
      })

    let expect = true
    let response: ResponseItem<KotlinBoolean> = try! Single.from(s).toBlocking(timeout: 10).first()!
    let actual = response.data?.boolValue

    XCTAssertEqual(expect, actual)
  }

  func testParseIntFromJsonString() {
    let json =
      """
      {
        "statusCode": "",
        "errorMsg": "",
        "node": "a5402fa77ba4",
        "data": 1
      }
      """

    let s: SingleWrapper<ResponseItem<NSNumber>> = Single
      .just(json)
      .asReaktiveResponseItem()

    let expect = 1
    let response: ResponseItem<NSNumber> = try! Single.from(s).toBlocking(timeout: 10).first()!
    let actual = response.data?.intValue

    XCTAssertEqual(expect, actual)
  }

  func testParseKotlinBooleanFromJsonString() {
    let json =
      """
      {
        "statusCode": "",
        "errorMsg": "",
        "node": "a5402fa77ba4",
        "data": true
      }
      """

    let s: SingleWrapper<ResponseItem<KotlinBoolean>> = Single
      .just(json)
      .asReaktiveResponseItem()

    let expect = true
    let response: ResponseItem<KotlinBoolean> = try! Single.from(s).toBlocking(timeout: 10).first()!
    let actual = response.data?.boolValue

    XCTAssertEqual(expect, actual)
  }

  func testParseStringFromJsonString() {
    let json =
      """
      {
        "statusCode": "",
        "errorMsg": "",
        "node": "a5402fa77ba4",
        "data": "true"
      }
      """

    let s: SingleWrapper<ResponseItem<NSString>> = Single
      .just(json)
      .asReaktiveResponseItem()

    let expect = "true"
    let response: ResponseItem<NSString> = try! Single.from(s).toBlocking(timeout: 10).first()!
    let actual = response.data as? String

    XCTAssertEqual(expect, actual)
  }
}
