//
//  ktobet_asia_iosTests.swift
//  ktobet-asia-iosTests
//
//  Created by Partick Chen on 2020/10/22.
//

import XCTest
@testable import ktobet_asia_ios

class ktobet_asia_iosTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testBranchName() throws {
        //chinese and english
        XCTAssertTrue("branchName".isValidRegex(format: .branchName), "英文可以")
        XCTAssertTrue("中文".isValidRegex(format: .branchName), "中文可以")
        XCTAssertFalse("2k".isValidRegex(format: .branchName), "數字不行")
        XCTAssertFalse("".isValidRegex(format: .branchName), "空白不行")
        XCTAssertFalse("qwertyuiopasdfghjklzxcvbnmqwertyuiop".isValidRegex(format: .branchName), "長度不超過31")
    }
    
}
