import Mockingbird
import sharedbu
import XCTest

@testable import ktobet_asia_ios

final class ProductsViewControllerTests: XCBaseTestCase {
    class MockProductsViewController: ProductsViewController {
        override func setProductType() -> ProductType {
            .none
        }
    }
  
    func test_whenAddFavoriteGameOverLimit_thenDisplayAlert() {
        let dummyMaintenanceViewModel = mock(MaintenanceViewModel.self)
            .initialize(mock(ISystemStatusUseCase.self), mock(AuthenticationUseCase.self))
        let mockAlert = mock(AlertProtocol.self)
    
        given(dummyMaintenanceViewModel.observeMaintenanceStatusChange()) ~> ()
        given(dummyMaintenanceViewModel.errors()) ~> .empty()
    
        Injection.shared.container
            .register(MaintenanceViewModel.self) { _ in
                dummyMaintenanceViewModel
            }
    
        Injection.shared.container
            .register(AlertProtocol.self) { _ in
                mockAlert
            }
    
        let sut = MockProductsViewController()
        sut.loadViewIfNeeded()
    
        sut.handleErrors(GameFavoriteReachMaxLimit(message: nil, errorCode: ""))
    
        verify(mockAlert.show(
            Localize.string("common_error"),
            Localize.string("product_favorite_reach_max"),
            confirm: any(),
            confirmText: any(),
            cancel: any(),
            cancelText: any(),
            tintColor: any()))
            .wasCalled()
    }
}
