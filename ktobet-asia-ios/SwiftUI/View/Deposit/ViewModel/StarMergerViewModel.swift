
import Foundation
import RxCocoa
import RxSwift
import SharedBu

protocol StarMergerViewModel: ObservableObject {
  var amountRange: AmountRange? { get set }
  var paymentLink: CommonDTO.WebPath? { get set }

  func getGatewayInformation()
}

class StarMergerViewModelImpl: ObservableObject, StarMergerViewModel {
  @Published var amountRange: AmountRange? = nil
  @Published var paymentLink: CommonDTO.WebPath? = nil

  let depositService: IDepositAppService
  let disposeBag = DisposeBag()

  init(depositService: IDepositAppService) {
    self.depositService = depositService
  }

  func getGatewayInformation() {
    if amountRange == nil, paymentLink == nil {
      RxSwift.Observable.from(depositService.getPayments()).first().flatMap({ paymentsDTO in
        RxSwift.Single.from(paymentsDTO!.cryptoMarket!.beneficiaries)
      }).subscribe(onSuccess: { (gateway: PaymentsDTO.CryptoMarketGateway) in
        self.amountRange = gateway.amountRange
        self.paymentLink = gateway.paymentLink
      }).disposed(by: disposeBag)
    }
  }
}
