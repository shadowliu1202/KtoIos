import RxSwift
import RxTest
import XCTest

@testable import ktobet_asia_ios_qat

final class SnackBarTests: XCBaseTestCase {
    let disposeBag = DisposeBag()
  
    func test_givenSnackBarShow_thenSnackBarIsDisplayed() {
        let sut = SnackBarImpl.shared as! SnackBarImpl

        sut.show(tip: "Test1", image: nil)

        wait(for: sut.DisappearTime - 0.5)

        let actual = sut.snackBarView.frame.origin.y < UIWindow.key!.frame.size.height
        XCTAssertTrue(actual)
    }
  
    func test_givenMultipleSnackBarShow_thenSnackBarThrottleIn3Seconds() {
        let sut = SnackBarImpl.shared as! SnackBarImpl
        let scheduler = TestScheduler(initialClock: 0)
      
        let result = scheduler.start(created: 0, subscribed: 0, disposed: 10) {
            Observable<Int>.of(1, 2, 3)
                .delay(.seconds(1), scheduler: scheduler)
                .map { "Snackbar\($0)" }
                .subscribe(onNext: {
                    sut.show(tip: $0, image: nil)
                })
                .disposed(by: self.disposeBag)
          
            return sut.getToastObservable(scheduler: scheduler)
        }
    
        let expect = ["Snackbar1", "Snackbar3"]
    
        let actual = result.events.compactMap { $0.value.element?.0 }
    
        XCTAssertEqual(expect, actual)
    }
}
