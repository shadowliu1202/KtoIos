import Foundation
import SharedBu

final class OfflinePaymentGatewayItemViewModel {
  let bank: PaymentsDTO.BankCard
  let name: String
  let icon: String
  let isSelected: Bool

  init(with bank: PaymentsDTO.BankCard, icon: String, isSelected: Bool) {
    self.bank = bank
    self.name = bank.name
    self.icon = icon
    self.isSelected = isSelected
  }
}

final class OnlinePaymentGatewayItemViewModel {
  let gateway: PaymentsDTO.Gateway
  let name: String
  let hint: String
  let icon: String
  let isSelected: Bool

  init(with gateway: PaymentsDTO.Gateway, icon: String = "Default(32)", isSelected: Bool) {
    self.gateway = gateway
    self.name = gateway.name
    self.hint = gateway.hint
    self.icon = icon
    self.isSelected = isSelected
  }
}
