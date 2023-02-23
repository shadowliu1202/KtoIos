import SharedBu

extension PaymentProvider {
  class func convert(_ id: Int) -> PaymentProvider {
    PaymentProvider.convertToPaymentProvider(id).1
  }

  class func convert(_ provider: PaymentProvider) -> Int {
    PaymentProvider.convertToPaymentProvider(provider).0
  }

  private class func convertToPaymentProvider(_ id: Any) -> (Int, PaymentProvider) {
    switch id {
    case let id as Int:
      switch id {
      case 0: return (0, PaymentProvider.evianpay)
      case 1: return (1, PaymentProvider.shanfu)
      case 2: return (2, PaymentProvider.wanhui)
      case 4: return (4, PaymentProvider.beifu)
      case 5: return (5, PaymentProvider.fy)
      case 7: return (7, PaymentProvider.weipay)
      case 9: return (9, PaymentProvider.yfpay)
      case 11: return (11, PaymentProvider.eeziepay)
      case 12: return (12, PaymentProvider.jpay)
      case 14: return (14, PaymentProvider.paywell)
      case 15: return (15, PaymentProvider.asiapay)
      case 17: return (17, PaymentProvider.jeepay)
      case 19: return (19, PaymentProvider.weilai)
      default: return (-1, PaymentProvider.undefined)
      }

    case let p as PaymentProvider:
      switch p {
      case PaymentProvider.evianpay: return (0, PaymentProvider.evianpay)
      case PaymentProvider.shanfu: return (1, PaymentProvider.shanfu)
      case PaymentProvider.wanhui: return (2, PaymentProvider.wanhui)
      case PaymentProvider.beifu: return (4, PaymentProvider.beifu)
      case PaymentProvider.fy: return (5, PaymentProvider.fy)
      case PaymentProvider.weipay: return (7, PaymentProvider.weipay)
      case PaymentProvider.yfpay: return (9, PaymentProvider.yfpay)
      case PaymentProvider.eeziepay: return (11, PaymentProvider.eeziepay)
      case PaymentProvider.jpay: return (12, PaymentProvider.jpay)
      case PaymentProvider.paywell: return (14, PaymentProvider.paywell)
      case PaymentProvider.asiapay: return (15, PaymentProvider.asiapay)
      case PaymentProvider.jeepay: return (17, PaymentProvider.jeepay)
      case PaymentProvider.weilai: return (19, PaymentProvider.weilai)
      default: return (-1, PaymentProvider.undefined)
      }
    default:
      return (-1, PaymentProvider.undefined)
    }
  }
}
