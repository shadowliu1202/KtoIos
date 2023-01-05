import SharedBu

extension ICurrencyUnit {
    /**
     format string with comma 100,000.11
     */
    func formatString(_ sign: FormatPattern.Currency = .normal) -> String {
        switch sign {
        case .none:
            return self.abs().amount()
        case .normal:
            return self.formatString(sign: .normal)
        case .signed:
            return self.formatString(sign: .signed_)
        }
    }
}

extension FormatPattern {
    
    enum Currency {
        /// Just amount string
        case none
        /// Only negtive have symbol. aka FormatPattern.Sign.Normal
        case normal
        /// Always have symbol, inculde 0 (+0). aka FormatPattern.Sign.Signed
        case signed
    }
}
