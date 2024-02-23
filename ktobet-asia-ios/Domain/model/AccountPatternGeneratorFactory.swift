import sharedbu

class AccountPatternGeneratorFactory {
  static func create(_ supportLocale: SupportLocale) -> AccountPatternGenerator {
    AccountPatternGeneratorCompanion().create(supportLocale: supportLocale)
  }

  static func transform(_ pattern: AccountPatternGenerator, _ e: AccountNameException?) -> String {
    guard let exception = e else { return "" }
    
    switch onEnum(of: exception) {
    case .conjunctiveBlank:
      return Localize.string("register_name_format_error_conjunctive_blank")
    case .emptyAccountName:
      return Localize.string("common_field_must_fill")
    case .exceededLength:
      return Localize.string("register_name_format_error_length_limitation", "\(pattern.withdrawalName().maxLength)")
    case .forbiddenLanguage:
      return Localize.string("register_name_format_error_only_vn_eng")
    case .forbiddenNumberOrSymbol:
      return Localize.string("register_name_format_error_no_number_symbol")
    case .headOrTailBlank:
      return Localize.string("register_name_format_error_blank_before_and_after")
    case .invalidNameFormat:
      return Localize.string("register_step2_name_format_error")
    }
  }
}
