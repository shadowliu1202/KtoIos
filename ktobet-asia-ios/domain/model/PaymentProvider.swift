import SharedBu

extension PaymentProvider_ {
    class func convert(_ id: Int) -> PaymentProvider_ {
        return PaymentProvider_.convertToPaymentProvider_(id).1
    }
    class func convert(_ provider: PaymentProvider_) -> Int {
        return PaymentProvider_.convertToPaymentProvider_(provider).0
    }
    private class func convertToPaymentProvider_(_ id: Any) -> (Int, PaymentProvider_) {
        switch id {
        case let id as Int:
            switch id {
            case 0:     return (0, PaymentProvider_.evianpay)
            case 1:     return (1, PaymentProvider_.shanfu)
            case 2:     return (2, PaymentProvider_.wanhui)
            case 4:     return (4, PaymentProvider_.beifu)
            case 5:     return (5, PaymentProvider_.fy)
            case 7:     return (7, PaymentProvider_.weipay)
            case 9:     return (9, PaymentProvider_.yfpay)
            case 11:    return (11, PaymentProvider_.eeziepay)
            case 12:    return (12, PaymentProvider_.jpay)
            case 14:    return (14, PaymentProvider_.paywell)
            case 15:    return (15, PaymentProvider_.asiapay)
            case 17:    return (17, PaymentProvider_.jeepay)
            case 19:    return (19, PaymentProvider_.weilai)
            default:    return (-1, PaymentProvider_.undefined)
            }
            
        case let p as PaymentProvider_:
            switch p {
            case PaymentProvider_.evianpay:  return (0, PaymentProvider_.evianpay)
            case PaymentProvider_.shanfu:    return (1, PaymentProvider_.shanfu)
            case PaymentProvider_.wanhui:    return (2, PaymentProvider_.wanhui)
            case PaymentProvider_.beifu:     return (4, PaymentProvider_.beifu)
            case PaymentProvider_.fy:        return (5, PaymentProvider_.fy)
            case PaymentProvider_.weipay:    return (7, PaymentProvider_.weipay)
            case PaymentProvider_.yfpay:     return (9, PaymentProvider_.yfpay)
            case PaymentProvider_.eeziepay:  return (11, PaymentProvider_.eeziepay)
            case PaymentProvider_.jpay:      return (12, PaymentProvider_.jpay)
            case PaymentProvider_.paywell:   return (14, PaymentProvider_.paywell)
            case PaymentProvider_.asiapay:   return (15, PaymentProvider_.asiapay)
            case PaymentProvider_.jeepay:    return (17, PaymentProvider_.jeepay)
            case PaymentProvider_.weilai:    return (19, PaymentProvider_.weilai)
            default:                        return (-1, PaymentProvider_.undefined)
            }
        default:
            return (-1, PaymentProvider_.undefined)
        }
    }
}
