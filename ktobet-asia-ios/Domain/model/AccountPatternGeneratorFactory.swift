import SharedBu

class AccountPatternGeneratorFactory {
  static func create(_ supportLocale: SupportLocale) -> AccountPatternGenerator {
    AccountPatternGeneratorCompanion().create(supportLocale: supportLocale)
  }

  static func transform(_ pattern: AccountPatternGenerator, _ e: AccountNameException?) -> String {
    guard let exception = e else { return "" }
    var result = ""
    switch exception {
    case is AccountNameException.EmptyAccountName:
      result = Localize.string("common_field_must_fill")
    case is AccountNameException.InvalidNameFormat:
      result = Localize.string("register_step2_name_format_error")
    case is AccountNameException.ForbiddenNumberOrSymbol:
      result = Localize.string("register_name_format_error_no_number_symbol")
    case is AccountNameException.ForbiddenLanguage:
      result = Localize.string("register_name_format_error_only_vn_eng")
    case is AccountNameException.ExceededLength:
      result = Localize.string("register_name_format_error_length_limitation", "\(pattern.withdrawalName().maxLength)")
    case is AccountNameException.ConjunctiveBlank:
      result = Localize.string("register_name_format_error_conjunctive_blank")
    case is AccountNameException.HeadOrTailBlank:
      result = Localize.string("register_name_format_error_blank_before_and_after")
    default:
      break
    }
    return result
  }
}
