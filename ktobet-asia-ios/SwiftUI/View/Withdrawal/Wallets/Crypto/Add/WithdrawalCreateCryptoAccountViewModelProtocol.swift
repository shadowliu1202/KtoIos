import SharedBu
import UIKit

protocol WithdrawalCreateCryptoAccountViewModelProtocol: AnyObject {
  var cryptoTypes: [String] { get }
  var cryptoNetworks: [String] { get }

  var addressVerifyErrorText: String { get }
  var aliasVerifyErrorText: String { get }

  var isCreateAccountEnable: Bool { get }

  var isLoading: Bool { get }

  var selectedCryptoType: String { get set }
  var selectedCryptoNetwork: String { get set }

  var accountAlias: String { get set }
  var accountAddress: String { get set }

  func setup()

  func readQRCode(image: UIImage?, onFailure: (() -> Void)?)

  func createCryptoAccount(onSuccess: ((_ bankCardId: String) -> Void)?)

  func getSupportLocale() -> SupportLocale
}
