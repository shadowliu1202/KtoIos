import SharedBu

extension ICurrencyUnit {
  func formatString(_ sign: FormatPattern.Sign = .normal) -> String {
    self.formatString(sign: sign)
  }
}
