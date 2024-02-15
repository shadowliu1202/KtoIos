import Mockingbird
import sharedbu
import SwiftUI
import SwinjectAutoregistration
import ViewInspector
import XCTest

@testable import ktobet_asia_ios_qat

final class LocalizeUtilsTests: XCTestCase {
  func test_givenPlayerFirstInstallAndPhoneLocaleIsCN_thenDisplayLocaleIsVN_KTO_TC_949() {
    let stubRepo = Injectable.resolveWrapper(LocalStorageRepository.self)
    stubRepo.setCultureCode(nil)
    let locale = Injectable ~> SupportLocale.self
    
    let appLocaleInitializer = AppLocaleInitializer(languageCode: "zh")
    appLocaleInitializer.initLocale()
    
    let sut = LocalizeUtils(supportLocale: locale)
    
    let expect = "Lưu Ý"
    let actual = sut.string("common_kindly_remind")
    
    XCTAssertEqual(expect, actual)
  }

  func test_givenPlayerFirstInstallAndPhoneLocaleIsVN_thenDisplayLocaleIsVN_KTO_TC_950() {
    let stubRepo = Injectable.resolveWrapper(LocalStorageRepository.self)
    stubRepo.setCultureCode(nil)
    let locale = Injectable ~> SupportLocale.self
    
    let appLocaleInitializer = AppLocaleInitializer(languageCode: "vi")
    appLocaleInitializer.initLocale()
    
    let sut = LocalizeUtils(supportLocale: locale)
    
    let expect = "Lưu Ý"
    let actual = sut.string("common_kindly_remind")
    
    XCTAssertEqual(expect, actual)
  }
  
  func test_givenAppDefaultLocaleIsVN_thenDisplayLocaleIsVN_KTO_TC_952() {
    let stubRepo = Injectable.resolveWrapper(LocalStorageRepository.self)
    stubRepo.setCultureCode("vi-vn")
    let locale = Injectable ~> SupportLocale.self
    
    let sut = LocalizeUtils(supportLocale: locale)
    
    let expect = "Lưu Ý"
    let actual = sut.string("common_kindly_remind")
    
    XCTAssertEqual(expect, actual)
  }
}
