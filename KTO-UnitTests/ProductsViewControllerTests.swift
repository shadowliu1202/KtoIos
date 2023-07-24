import Mockingbird
import SharedBu
import XCTest

@testable import ktobet_asia_ios_qat

final class ProductsViewControllerTests: XCBaseTestCase {
  class MockProductsViewController: ProductsViewController {
    override func setProductType() -> ProductType {
      .none
    }
  }
  
  func test_whenAddFavoriteGameOverLimit_thenDisplayAlert() {
    let dummySystemStatusUseCase = mock(GetSystemStatusUseCase.self)
    let dummyLocalStorageRepo = mock(LocalStorageRepository.self)
    let dummyPlayerUseCase = mock(PlayerDataUseCase.self)
    let dummyAuthUseCase = mock(AuthenticationUseCase.self)
    let dummyObserveSystemMessageUseCase = mock(ObserveSystemMessageUseCase.self)
    
    given(dummySystemStatusUseCase.getOtpStatus()) ~> .just(.init(isMailActive: true, isSmsActive: true))
    given(dummySystemStatusUseCase.getCustomerServiceEmail()) ~> .just("")
    given(dummySystemStatusUseCase.observePortalMaintenanceState()) ~> .just(.Product(productsAvailable: [], status: [:]))
    
    let dummyServiceViewModel = mock(ServiceStatusViewModel.self)
      .initialize(systemStatusUseCase: dummySystemStatusUseCase, localStorageRepo: dummyLocalStorageRepo)
    let dummyPlayerViewModel = mock(PlayerViewModel.self)
      .initialize(playerUseCase: dummyPlayerUseCase, authUseCase: dummyAuthUseCase)
    let stubProductsViewModel = mock(ProductsViewModel.self)
      .initialize(observeSystemMessageUseCase: dummyObserveSystemMessageUseCase, getSystemStatusUseCase: dummySystemStatusUseCase)
    let mockAlert = mock(AlertProtocol.self)
    
    given(dummyPlayerViewModel.checkIsLogged()) ~> .just(true)
    given(stubProductsViewModel.observeMaintenanceStatus()) ~> .just(.Product(productsAvailable: [], status: [:]))
    given(stubProductsViewModel.errors()) ~> .empty()
    
    Injection.shared.container
      .register(ServiceStatusViewModel.self) { _ in
        dummyServiceViewModel
      }
    
    Injection.shared.container
      .register(PlayerViewModel.self) { _ in
        dummyPlayerViewModel
      }
    
    Injection.shared.container
      .register(ProductsViewModel.self) { _ in
        stubProductsViewModel
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
