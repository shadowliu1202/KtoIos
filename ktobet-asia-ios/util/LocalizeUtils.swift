import Foundation
import SharedBu

private var _Localize = Injectable.resolve(LocalizeUtils.self)!

var Localize: LocalizeUtils {
  get { _Localize }
  set {
    if !isTesting {
      fatalError("Only allow change when testing !!")
    }
    else {
      _Localize = newValue
    }
  }
}

class LocalizeUtils: NSObject {
  private let localStorageRepo: LocalStorageRepository

  init(localStorageRepo: LocalStorageRepository) {
    self.localStorageRepo = localStorageRepo
  }

  func string(_ key: String, _ parameters: [String]) -> String {
    let localizationFileName = localStorageRepo.getCultureCode()
    let path = Bundle.main.path(forResource: localizationFileName, ofType: "lproj")
    let bundle = Bundle(path: path!)
    return String(
      format: NSLocalizedString(key, tableName: nil, bundle: bundle!, value: "", comment: ""),
      arguments: parameters)
  }

  func string(_ key: String, _ parameters: String...) -> String {
    let localizationFileName = localStorageRepo.getCultureCode()
    let path = Bundle.main.path(forResource: localizationFileName, ofType: "lproj")
    let bundle = Bundle(path: path!)
    return String(
      format: NSLocalizedString(key, tableName: nil, bundle: bundle!, value: "", comment: ""),
      arguments: parameters)
  }

  func string(_ key: String, _ parameter: String? = nil) -> String {
    let localizationFileName = localStorageRepo.getCultureCode()
    let path = Bundle.main.path(forResource: localizationFileName, ofType: "lproj")
    let bundle = Bundle(path: path!)
    if let parameter {
      return String(format: NSLocalizedString(key, tableName: nil, bundle: bundle!, value: "", comment: ""), parameter)
    }
    else {
      return NSLocalizedString(key, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
  }

  func string(_ key: String) -> String {
    let localizationFileName = localStorageRepo.getCultureCode()
    let path = Bundle.main.path(forResource: localizationFileName, ofType: "lproj")
    let bundle = Bundle(path: path!)
    return NSLocalizedString(key, tableName: nil, bundle: bundle!, value: "", comment: "")
  }

  private var aRegex = "[ÀÁÂÃĂàáâãăẠẢẤẦẨẪẬẮẰẲẴẶạảấầẩẫậắằẳẵặ]"
  private var eRegex = "[ÈÉÊèéêẸẺẼỀỂẾẹẻẽềểếỄỆễệ]"
  private var iRegex = "[ÌÍĨìíĩỈỊỉị]"
  private var oRegex = "[ÒÓÔÕƠòóôõơỌỎỐỒỔỖỘỚỜỞỠỢọỏốồổỗộớờởỡợ]"
  private var uRegex = "[ÙÚŨùúũƯưỤỦỨỪụủứừỬỮỰửữự]"
  private var dRegex = "[Đđ]"
  private var yRegex = "[ỲỴÝỶỸỳỵỷỹý]"

  func removeAccent(str: String) -> String {
    var result: String
    do {
      result = try str.replacingRegex(matching: aRegex, with: "a")
        .replacingRegex(matching: eRegex, with: "e")
        .replacingRegex(matching: iRegex, with: "i")
        .replacingRegex(matching: oRegex, with: "o")
        .replacingRegex(matching: uRegex, with: "u")
        .replacingRegex(matching: dRegex, with: "d")
        .replacingRegex(matching: yRegex, with: "y")
    }
    catch {
      result = str
      print(error)
    }
    return result
  }
}

extension LocalizeUtils: StringSupporter {
  func convert(resourceId: ResourceKey, args: KotlinArray<AnyObject>) -> KotlinLazy {
    let key = resourceId.asString()
    if args.size > 0 {
      var parameters: [String] = []
      for idx in 0..<args.size {
        if let num = args.get(index: idx), num is Double || num is Int32 {
          parameters.append("\(num)")
        }
        else if let str = args.get(index: idx), str is String {
          parameters.append(str as! String)
        }
        else if let cashAmount = args.get(index: idx), cashAmount is AccountCurrency {
          let amount = cashAmount as! AccountCurrency
          parameters.append(amount.description())
        }
        else if let unknown = args.get(index: idx) {
          print(">>>>>>>StringSupporter unknown type arg: \(type(of: unknown))")
          fatalError("please implements it")
        }
        else {
          print(">>>>>>>StringSupporter option type arg: \(type(of: args.get(index: idx)))")
        }
      }
      return KNLazyCompanion().create(input: self.string(key, parameters))
    }
    else {
      return KNLazyCompanion().create(input: self.string(key))
    }
  }

  func convert(resourceId: ResourceKey) -> KotlinLazy {
    let key = resourceId.asString()
    return KNLazyCompanion().create(input: self.string(key))
  }
}
