import SharedBu

extension ICurrencyUnit {
    /**
     format string with comma 100,000.11
     */
    func formatString(_ sign: FormatPattern.Sign = .none) -> String {
        self.formatString(sign: sign)
    }
}
